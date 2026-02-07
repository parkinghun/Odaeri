//
//  NavigationService.swift
//  Odaeri
//
//  Created by 박성훈 on 1/7/26.
//

import Foundation
import Combine
import CoreLocation
import MapKit

enum NavigationState {
    case idle  // 아무것도 안 하는 상태 (리소스 낭비 방지)
    case navigating // 실시간 추적 중
    case arrived  // 목적지 반경 10m 안으로 들어옴. (성공적인 종료 처리)
    case offRoute  // 경로 이탈. (재탐색 유도)
}

// 사용자의 이동 속도를 실시간으로 모니터링하여 MovementState를 동적으로 전환하도록 설계
enum MovementState {
    case stationary
    case walking
    case moving

    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .stationary:
            return kCLLocationAccuracyHundredMeters
        case .walking:
            return kCLLocationAccuracyNearestTenMeters
        case .moving:
            return kCLLocationAccuracyBest
        }
    }

    var distanceFilter: CLLocationDistance {
        switch self {
        case .stationary:
            return 50.0
        case .walking:
            return 10.0
        case .moving:
            return 5.0
        }
    }
}

struct NavigationConfig {
    static let localSearchWindowSize = 20
    static let deviationBaseThreshold: CLLocationDistance = 50.0
    static let deviationMaxThreshold: CLLocationDistance = 100.0
    static let offRouteConfirmCount: Int = 5
    static let deviationResetThreshold: CLLocationDistance = 100.0
    static let arrivalRadius: CLLocationDistance = 10.0
    static let reroutingDebounceInterval: TimeInterval = 4.0
    static let stationarySpeedThreshold: CLLocationSpeed = 0.5
    static let walkingSpeedThreshold: CLLocationSpeed = 2.0
    static let snapDistanceStationary: CLLocationDistance = 30.0
    static let snapDistanceWalking: CLLocationDistance = 25.0
    static let snapDistanceMoving: CLLocationDistance = 20.0
    static let minPassedPathDistance: CLLocationDistance = 1.5
    static let maxPassedPathTimeInterval: TimeInterval = 2.0
}

final class NavigationService: NSObject {
    static let shared = NavigationService()

    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()

    private var route: MKRoute?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var currentRouteIndex = 0
    private var lastDeviationCheckTime: Date?
    private var deviationCount = 0
    private var hasShownOffRouteAlert = false
    private var smoothedLocationBuffer: [CLLocationCoordinate2D] = []
    private var lastPassedCoordinate: CLLocationCoordinate2D?
    private var lastPassedTime: Date?
    private var lastValidBearing: CLLocationDirection?
    private var lastProjectedCoordinate: CLLocationCoordinate2D?

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var currentHeading: CLHeading?
    @Published private(set) var navigationState: NavigationState = .idle
    @Published private(set) var movementState: MovementState = .stationary
    @Published private(set) var distanceToDestination: CLLocationDistance = 0
    @Published private(set) var estimatedTimeRemaining: TimeInterval = 0
    @Published private(set) var passedPath: [CLLocationCoordinate2D] = []
    @Published private(set) var remainingPath: [CLLocationCoordinate2D] = []

    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        locationManager.activityType = .otherNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }

    func startNavigation(with route: MKRoute) {
        self.route = route
        self.routeCoordinates = extractCoordinates(from: route.polyline)
        self.currentRouteIndex = 0
        self.navigationState = .navigating
        self.deviationCount = 0
        self.hasShownOffRouteAlert = false
        self.passedPath = []
        self.remainingPath = routeCoordinates

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopNavigation() {
        navigationState = .idle
        route = nil
        routeCoordinates = []
        currentRouteIndex = 0
        passedPath = []
        remainingPath = []
        deviationCount = 0
        hasShownOffRouteAlert = false
        lastValidBearing = nil
        lastPassedCoordinate = nil
        lastPassedTime = nil
        lastProjectedCoordinate = nil

        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    private func extractCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        return coordinates
    }

    private func updateLocation(_ location: CLLocation) {
        currentLocation = location

        guard navigationState == .navigating || navigationState == .offRoute else { return }

        updateMovementState(location)
        updateRouteProgress(location)
        checkArrival(location)
        checkDeviation(location)
    }

    private func updateMovementState(_ location: CLLocation) {
        let speed = location.speed

        let newState: MovementState
        if speed < NavigationConfig.stationarySpeedThreshold {
            newState = .stationary
        } else if speed < NavigationConfig.walkingSpeedThreshold {
            newState = .walking
        } else {
            newState = .moving
        }

        if newState != movementState {
            movementState = newState
            locationManager.desiredAccuracy = newState.desiredAccuracy
            locationManager.distanceFilter = newState.distanceFilter
        }
    }

    private func updateRouteProgress(_ location: CLLocation) {
        guard !routeCoordinates.isEmpty else { return }

        updatePathSegments()
        updateDistanceAndTime(from: location)
    }

    private func findClosestPointOnRoute(from location: CLLocation) -> Int {
        guard !routeCoordinates.isEmpty else { return 0 }

        if currentRouteIndex >= routeCoordinates.count - 1 {
            return routeCoordinates.count - 1
        }

        let currentPoint = CLLocation(
            latitude: routeCoordinates[currentRouteIndex].latitude,
            longitude: routeCoordinates[currentRouteIndex].longitude
        )
        let distanceToCurrent = location.distance(from: currentPoint)

        let maxLookAhead = 5
        var bestIndex = currentRouteIndex
        var minDistance = distanceToCurrent

        for i in (currentRouteIndex + 1)...min(currentRouteIndex + maxLookAhead, routeCoordinates.count - 1) {
            let routeLocation = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            let distance = location.distance(from: routeLocation)

            if distance < minDistance {
                minDistance = distance
                bestIndex = i
            } else {
                break
            }
        }

        if bestIndex != currentRouteIndex {
            print("[RouteIndex] Updated: \(currentRouteIndex) → \(bestIndex) (distance: \(String(format: "%.1f", minDistance))m)")
        }

        if minDistance > NavigationConfig.deviationResetThreshold {
            print("[RouteIndex] Too far from route, searching globally")
            return findGlobalClosestPoint(from: location)
        }

        return bestIndex
    }

    private func findGlobalClosestPoint(from location: CLLocation) -> Int {
        var closestIndex = 0
        var minDistance = CLLocationDistance.greatestFiniteMagnitude

        for (index, coordinate) in routeCoordinates.enumerated() {
            let routeLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            let distance = location.distance(from: routeLocation)

            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }

        return closestIndex
    }

    private func updatePathSegments() {
        guard !routeCoordinates.isEmpty, let location = currentLocation else { return }

        let projectionResult = projectLocationOntoRoute(location)
        let projectedCoordinate = projectionResult.coordinate
        let segmentIndex = projectionResult.segmentIndex

        if let lastProjected = lastProjectedCoordinate {
            let lastLocation = CLLocation(latitude: lastProjected.latitude, longitude: lastProjected.longitude)
            let newLocation = CLLocation(latitude: projectedCoordinate.latitude, longitude: projectedCoordinate.longitude)
            let distance = newLocation.distance(from: lastLocation)

            if distance < 2.0 {
                return
            }
        }

        lastProjectedCoordinate = projectedCoordinate
        currentRouteIndex = segmentIndex

        var coordinates = [projectedCoordinate]
        if segmentIndex + 1 < routeCoordinates.count {
            coordinates.append(contentsOf: routeCoordinates[(segmentIndex + 1)..<routeCoordinates.count])
        }

        remainingPath = coordinates

        if let last = lastProjectedCoordinate {
            let movedDistance = CLLocation(latitude: last.latitude, longitude: last.longitude).distance(from: CLLocation(latitude: projectedCoordinate.latitude, longitude: projectedCoordinate.longitude))
            print("[PathSegments] Projected to segment \(segmentIndex), remainingPath=\(remainingPath.count) coords, distance moved: \(String(format: "%.1f", movedDistance))m")
        } else {
            print("[PathSegments] Projected to segment \(segmentIndex), remainingPath=\(remainingPath.count) coords (first projection)")
        }
    }

    private func updateDistanceAndTime(from location: CLLocation) {
        guard let route = route else { return }

        var totalDistance: CLLocationDistance = 0
        for i in currentRouteIndex..<(routeCoordinates.count - 1) {
            let start = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            let end = CLLocation(
                latitude: routeCoordinates[i + 1].latitude,
                longitude: routeCoordinates[i + 1].longitude
            )
            totalDistance += start.distance(from: end)
        }

        distanceToDestination = totalDistance

        let progress = Double(currentRouteIndex) / Double(max(routeCoordinates.count - 1, 1))
        let remainingRatio = 1.0 - progress
        estimatedTimeRemaining = route.expectedTravelTime * remainingRatio
    }

    private func checkArrival(_ location: CLLocation) {
        guard let destination = routeCoordinates.last else { return }

        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        let distance = location.distance(from: destinationLocation)

        if distance <= NavigationConfig.arrivalRadius {
            navigationState = .arrived
            stopNavigation()
        }
    }

    private func checkDeviation(_ location: CLLocation) {
        guard !routeCoordinates.isEmpty else { return }

        let halfWindow = NavigationConfig.localSearchWindowSize / 2
        let searchStart = max(currentRouteIndex - halfWindow, 0)
        let searchEnd = min(currentRouteIndex + halfWindow, routeCoordinates.count - 1)

        var minDistance = CLLocationDistance.greatestFiniteMagnitude

        for i in searchStart...searchEnd {
            let routeLocation = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            let distance = location.distance(from: routeLocation)

            if distance < minDistance {
                minDistance = distance
            }
        }

        let threshold: CLLocationDistance
        switch movementState {
        case .stationary:
            threshold = NavigationConfig.snapDistanceStationary + 20.0
        case .walking:
            threshold = NavigationConfig.snapDistanceWalking + 25.0
        case .moving:
            threshold = NavigationConfig.snapDistanceMoving + 20.0
        }

        if minDistance > threshold {
            deviationCount += 1
            print("[Deviation] Off route count: \(deviationCount)/\(NavigationConfig.offRouteConfirmCount), distance: \(String(format: "%.1f", minDistance))m > \(String(format: "%.1f", threshold))m")

            if deviationCount >= NavigationConfig.offRouteConfirmCount {
                if navigationState != .offRoute {
                    print("[Deviation] State changed to OFF_ROUTE")
                    navigationState = .offRoute
                }
                if !hasShownOffRouteAlert {
                    hasShownOffRouteAlert = true
                }
            }
        } else {
            if deviationCount > 0 {
                print("[Deviation] Back on route: distance=\(String(format: "%.1f", minDistance))m, resetting count")
            }
            lastDeviationCheckTime = nil
            deviationCount = 0

            if navigationState == .offRoute {
                print("[Deviation] State changed to NAVIGATING")
                navigationState = .navigating
                hasShownOffRouteAlert = false
            }
        }
    }

    private func updatePassedPathWithGPS(_ location: CLLocation) {
        guard shouldAcceptLocation(location) else {
            print("[PassedPath] Location rejected by accuracy filter: \(location.horizontalAccuracy)m")
            return
        }

        let coordinate = location.coordinate
        let smoothed = appendAndSmooth(coordinate)

        let smoothedLocation = CLLocation(latitude: smoothed.latitude, longitude: smoothed.longitude)
        let snapped = snapToRouteIfClose(smoothedLocation)

        let now = Date()
        var shouldAdd = false

        if let last = lastPassedCoordinate, let lastTime = lastPassedTime {
            let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let newLocation = CLLocation(latitude: snapped.latitude, longitude: snapped.longitude)
            let distance = newLocation.distance(from: lastLocation)
            let timeElapsed = now.timeIntervalSince(lastTime)

            if distance >= NavigationConfig.minPassedPathDistance {
                shouldAdd = true
                print("[PassedPath] Adding coordinate: distance=\(String(format: "%.1f", distance))m")
            } else if timeElapsed >= NavigationConfig.maxPassedPathTimeInterval {
                shouldAdd = true
                print("[PassedPath] Adding coordinate: time elapsed=\(String(format: "%.1f", timeElapsed))s")
            } else {
                print("[PassedPath] Skipping: distance=\(String(format: "%.1f", distance))m, time=\(String(format: "%.1f", timeElapsed))s")
            }
        } else {
            shouldAdd = true
            print("[PassedPath] Adding first coordinate")
        }

        if shouldAdd {
            lastPassedCoordinate = snapped
            lastPassedTime = now
            passedPath.append(snapped)
            print("[PassedPath] Total coordinates: \(passedPath.count)")
        }
    }

    // 방향 계산 - 두 좌표 간의 방위각(bearing)을 계산하여 0~360도 범위로 반환
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    private func getExpectedBearing(at index: Int) -> CLLocationDirection {
        guard index < routeCoordinates.count - 1 else {
            return lastValidBearing ?? 0
        }

        let current = routeCoordinates[index]
        let next = routeCoordinates[min(index + 5, routeCoordinates.count - 1)]
        return calculateBearing(from: current, to: next)
    }

    private func isValidDirection(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let last = lastPassedCoordinate else { return true }

        let bearing = calculateBearing(from: last, to: coordinate)
        let expected = getExpectedBearing(at: currentRouteIndex)

        var difference = abs(bearing - expected)
        if difference > 180 {
            difference = 360 - difference
        }

        if difference > 120 {
            print("[GPS Filter] Rejected: bearing=\(Int(bearing))°, expected=\(Int(expected))°, diff=\(Int(difference))°")
            return false
        }

        lastValidBearing = bearing
        return true
    }

    private func shouldAcceptLocation(_ location: CLLocation) -> Bool {
        let accuracy = location.horizontalAccuracy
        guard accuracy >= 0 else { return false }

        let maxAccuracy: CLLocationDistance
        switch movementState {
        case .stationary:
            maxAccuracy = 100
        case .walking:
            maxAccuracy = 150
        case .moving:
            maxAccuracy = 150
        }

        guard accuracy <= maxAccuracy else {
            return false
        }

        return true
    }

    private func appendAndSmooth(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        smoothedLocationBuffer.append(coordinate)

        let windowSize: Int
        switch movementState {
        case .stationary:
            windowSize = 7
        case .walking:
            windowSize = 5
        case .moving:
            windowSize = 3
        }

        if smoothedLocationBuffer.count > windowSize {
            smoothedLocationBuffer.removeFirst(smoothedLocationBuffer.count - windowSize)
        }

        let sum = smoothedLocationBuffer.reduce((lat: 0.0, lon: 0.0)) { partial, coord in
            (lat: partial.lat + coord.latitude, lon: partial.lon + coord.longitude)
        }
        let count = Double(smoothedLocationBuffer.count)
        return CLLocationCoordinate2D(latitude: sum.lat / count, longitude: sum.lon / count)
    }

    private func adaptiveDeviationThreshold(for location: CLLocation) -> CLLocationDistance {
        let accuracy = max(0, location.horizontalAccuracy)
        let base = NavigationConfig.deviationBaseThreshold
        let maxThreshold = NavigationConfig.deviationMaxThreshold
        if accuracy <= 15 {
            return base
        }
        let adjusted = base + (accuracy - 15)
        return min(max(adjusted, base), maxThreshold)
    }

    private func snapToRouteIfClose(_ location: CLLocation) -> CLLocationCoordinate2D {
        guard !routeCoordinates.isEmpty else { return location.coordinate }

        let snapThreshold: CLLocationDistance
        switch movementState {
        case .stationary:
            snapThreshold = NavigationConfig.snapDistanceStationary
        case .walking:
            snapThreshold = NavigationConfig.snapDistanceWalking
        case .moving:
            snapThreshold = NavigationConfig.snapDistanceMoving
        }

        let halfWindow = NavigationConfig.localSearchWindowSize / 2
        let searchStart = max(currentRouteIndex - halfWindow, 0)
        let searchEnd = min(currentRouteIndex + halfWindow, routeCoordinates.count - 1)

        var closestCoordinate = routeCoordinates[currentRouteIndex]
        var minDistance = CLLocationDistance.greatestFiniteMagnitude

        for i in searchStart...searchEnd {
            let routeLocation = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            let distance = location.distance(from: routeLocation)

            if distance < minDistance {
                minDistance = distance
                closestCoordinate = routeCoordinates[i]
            }
        }

        if minDistance <= snapThreshold {
            print("[Snap] Snapped to route: distance=\(String(format: "%.1f", minDistance))m, threshold=\(String(format: "%.1f", snapThreshold))m")
            return closestCoordinate
        } else {
            print("[Snap] No snap: distance=\(String(format: "%.1f", minDistance))m > threshold=\(String(format: "%.1f", snapThreshold))m")
            return location.coordinate
        }
    }

    private func projectLocationOntoRoute(_ location: CLLocation) -> (coordinate: CLLocationCoordinate2D, segmentIndex: Int) {
        guard routeCoordinates.count >= 2 else {
            return (location.coordinate, 0)
        }

        let searchStart = max(currentRouteIndex - 5, 0)
        let searchEnd = min(currentRouteIndex + 15, routeCoordinates.count - 2)

        var closestSegmentIndex = currentRouteIndex
        var minDistance = CLLocationDistance.greatestFiniteMagnitude
        var bestProjection = location.coordinate

        for i in searchStart...searchEnd {
            let segmentStart = routeCoordinates[i]
            let segmentEnd = routeCoordinates[i + 1]

            let projection = projectPointOntoSegment(
                point: location.coordinate,
                segmentStart: segmentStart,
                segmentEnd: segmentEnd
            )

            let projectedLocation = CLLocation(latitude: projection.latitude, longitude: projection.longitude)
            let distance = location.distance(from: projectedLocation)

            if distance < minDistance {
                minDistance = distance
                closestSegmentIndex = i
                bestProjection = projection
            }
        }

        print("[Projection] Location projected to segment \(closestSegmentIndex), distance: \(String(format: "%.1f", minDistance))m")
        return (bestProjection, closestSegmentIndex)
    }

    private func projectPointOntoSegment(
        point: CLLocationCoordinate2D,
        segmentStart: CLLocationCoordinate2D,
        segmentEnd: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        let dx = segmentEnd.longitude - segmentStart.longitude
        let dy = segmentEnd.latitude - segmentStart.latitude

        if dx == 0 && dy == 0 {
            return segmentStart
        }

        let t = ((point.longitude - segmentStart.longitude) * dx + (point.latitude - segmentStart.latitude) * dy) / (dx * dx + dy * dy)

        let clampedT = max(0, min(1, t))

        let projectedLat = segmentStart.latitude + clampedT * dy
        let projectedLon = segmentStart.longitude + clampedT * dx

        return CLLocationCoordinate2D(latitude: projectedLat, longitude: projectedLon)
    }

    func createCameraForCurrentLocation(
        pitch: CGFloat = 60,
        heading: CLLocationDirection? = nil,
        altitude: CLLocationDistance = 500
    ) -> MKMapCamera? {
        guard let location = currentLocation else { return nil }

        let camera = MKMapCamera(
            lookingAtCenter: location.coordinate,
            fromDistance: altitude,
            pitch: pitch,
            heading: heading ?? currentHeading?.trueHeading ?? 0
        )

        return camera
    }
}

extension NavigationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted")
        case .denied, .restricted:
            print("Location permission denied")
        case .notDetermined:
            print("Location permission not determined")
        @unknown default:
            break
        }
    }
}
