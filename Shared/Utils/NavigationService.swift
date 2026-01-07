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
    static let localSearchWindowSize = 10
    static let deviationThreshold: CLLocationDistance = 30.0
    static let deviationResetThreshold: CLLocationDistance = 100.0
    static let arrivalRadius: CLLocationDistance = 10.0
    static let reroutingDebounceInterval: TimeInterval = 4.0
    static let stationarySpeedThreshold: CLLocationSpeed = 0.5
    static let walkingSpeedThreshold: CLLocationSpeed = 2.0
}

final class NavigationService: NSObject {
    static let shared = NavigationService()

    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()

    private var route: MKRoute?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var currentRouteIndex = 0
    private var lastDeviationCheckTime: Date?

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

        updatePathSegments()

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

        guard navigationState == .navigating else { return }

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

        let closestIndex = findClosestPointOnRoute(from: location)
        currentRouteIndex = closestIndex

        updatePathSegments()
        updateDistanceAndTime(from: location)
    }

    private func findClosestPointOnRoute(from location: CLLocation) -> Int {
        guard !routeCoordinates.isEmpty else { return 0 }

        let halfWindow = NavigationConfig.localSearchWindowSize / 2

        let searchStart = max(currentRouteIndex - halfWindow, 0)
        let searchEnd = min(currentRouteIndex + halfWindow, routeCoordinates.count - 1)

        var closestIndex = currentRouteIndex
        var minDistance = CLLocationDistance.greatestFiniteMagnitude

        for i in searchStart...searchEnd {
            let routeLocation = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            let distance = location.distance(from: routeLocation)

            if distance < minDistance && i >= currentRouteIndex {
                minDistance = distance
                closestIndex = i
            }
        }

        if minDistance > NavigationConfig.deviationResetThreshold {
            return findGlobalClosestPoint(from: location)
        }

        return closestIndex
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
        guard !routeCoordinates.isEmpty else { return }

        passedPath = Array(routeCoordinates[0...currentRouteIndex])
        remainingPath = Array(routeCoordinates[currentRouteIndex..<routeCoordinates.count])
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
        guard currentRouteIndex < routeCoordinates.count else { return }

        let routeLocation = CLLocation(
            latitude: routeCoordinates[currentRouteIndex].latitude,
            longitude: routeCoordinates[currentRouteIndex].longitude
        )

        let distance = location.distance(from: routeLocation)

        if distance > NavigationConfig.deviationThreshold {
            let now = Date()

            if let lastCheck = lastDeviationCheckTime {
                let elapsed = now.timeIntervalSince(lastCheck)

                if elapsed >= NavigationConfig.reroutingDebounceInterval {
                    navigationState = .offRoute
                    lastDeviationCheckTime = nil
                }
            } else {
                lastDeviationCheckTime = now
            }
        } else {
            lastDeviationCheckTime = nil

            if navigationState == .offRoute {
                navigationState = .navigating
            }
        }
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
