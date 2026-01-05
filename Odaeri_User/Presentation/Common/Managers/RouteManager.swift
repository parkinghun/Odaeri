//
//  RouteManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import MapKit
import Combine

final class RouteManager {
    static let shared = RouteManager()

    // MARK: - Properties

    /// 경로 계산 결과를 방출하는 Subject
    let routeSubject = PassthroughSubject<MKRoute, Never>()

    /// 경로 에러를 방출하는 Subject
    let routeErrorSubject = PassthroughSubject<RouteError, Never>()

    /// 성인 평균 보폭 (미터)
    private let averageStrideLength: Double = 0.7

    /// 평균 도보 속도 (km/h)
    private let averageWalkingSpeed: Double = 4.0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 도보 경로 계산
    /// - Parameters:
    ///   - source: 출발지 좌표
    ///   - destination: 목적지 좌표
    func calculateWalkingRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        // 1. MKPlacemark 생성
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        // 2. MKMapItem 생성
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        // 3. MKDirections.Request 설정
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .walking // 도보 경로
        request.requestsAlternateRoutes = false // 대체 경로 미요청

        // 4. MKDirections 생성 및 경로 계산
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }

            // 에러 처리
            if let error = error {
                self.handleDirectionsError(error)
                return
            }

            // 응답 체크
            guard let response = response else {
                self.routeErrorSubject.send(.noRouteFound)
                return
            }

            // 경로 체크
            guard let route = response.routes.first else {
                self.routeErrorSubject.send(.noRouteFound)
                return
            }

            // 경로 방출
            self.routeSubject.send(route)
        }
    }

    /// 도보 경로 계산 (Async/Await)
    /// - Parameters:
    ///   - source: 출발지 좌표
    ///   - destination: 목적지 좌표
    /// - Returns: 계산된 경로
    func calculateWalkingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        // 1. MKPlacemark 생성
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        // 2. MKMapItem 생성
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        // 3. MKDirections.Request 설정
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        // 4. MKDirections 생성 및 경로 계산
        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            guard let route = response.routes.first else {
                throw RouteError.noRouteFound
            }

            return route

        } catch {
            throw mapDirectionsError(error)
        }
    }

    /// 두 좌표 간 직선 거리 계산 (km)
    /// - Parameters:
    ///   - from: 시작 좌표
    ///   - to: 목적지 좌표
    /// - Returns: 거리 (km)
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)

        let distanceInMeters = fromLocation.distance(from: toLocation)
        return distanceInMeters / 1000.0 // km로 변환
    }

    /// 거리를 기반으로 예상 걸음 수 계산
    /// - Parameter distanceInKm: 거리 (km)
    /// - Returns: 예상 걸음 수
    func calculateEstimatedSteps(distanceInKm: Double) -> Int {
        let distanceInMeters = distanceInKm * 1000.0
        let steps = distanceInMeters / averageStrideLength
        return Int(steps)
    }

    /// 거리를 기반으로 예상 도보 시간 계산
    /// - Parameter distanceInKm: 거리 (km)
    /// - Returns: 예상 시간 (초)
    func calculateEstimatedTime(distanceInKm: Double) -> TimeInterval {
        let hours = distanceInKm / averageWalkingSpeed
        return hours * 3600
    }

    /// 시간을 포맷팅 (분/시간/시간, 분)
    /// - Parameter seconds: 시간 (초)
    /// - Returns: 포맷팅된 시간 문자열
    func formatTime(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)

        if totalMinutes < 60 {
            return "\(totalMinutes)분"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)시간"
            }
            return "\(hours)시간 \(minutes)분"
        }
    }

    // MARK: - Private Methods

    private func handleDirectionsError(_ error: Error) {
        let routeError = mapDirectionsError(error)
        routeErrorSubject.send(routeError)
    }

    private func mapDirectionsError(_ error: Error) -> RouteError {
        if let mkError = error as? MKError {
            switch mkError.code {
            case .placemarkNotFound:
                return .placemarkNotFound

            case .directionsNotFound:
                return .noRouteFound

            case .serverFailure:
                return .serverError

            case .loadingThrottled:
                return .networkError

            default:
                return .unknown
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }

        return .unknown
    }
}

// MARK: - RouteError

enum RouteError: LocalizedError {
    case noRouteFound
    case placemarkNotFound
    case networkError
    case serverError
    case unknown

    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "경로를 찾을 수 없습니다."

        case .placemarkNotFound:
            return "위치를 찾을 수 없습니다."

        case .networkError:
            return "네트워크 오류가 발생했습니다."

        case .serverError:
            return "서버 오류가 발생했습니다."

        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
