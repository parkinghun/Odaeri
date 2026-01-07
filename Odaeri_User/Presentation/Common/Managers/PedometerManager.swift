//
//  PedometerManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import CoreMotion
import Combine

final class PedometerManager {
    static let shared = PedometerManager()

    // MARK: - Properties

    private let pedometer = CMPedometer()

    /// 걸음 수 업데이트를 방출하는 Subject
    let stepCountSubject = PassthroughSubject<Int, Never>()

    /// 거리 업데이트를 방출하는 Subject (km 단위)
    let distanceSubject = PassthroughSubject<Double, Never>()

    /// Pedometer 에러를 방출하는 Subject
    let pedometerErrorSubject = PassthroughSubject<PedometerError, Never>()

    /// Pedometer 사용 가능 여부
    var isAvailable: Bool {
        return CMPedometer.isStepCountingAvailable()
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 걸음 수 추적 시작
    /// - Parameter startDate: 추적 시작 시간 (기본값: 현재 시간)
    func startTracking(from startDate: Date = Date()) {
        // 1. 걸음 수 추적 기능 사용 가능 여부 확인
        guard CMPedometer.isStepCountingAvailable() else {
            pedometerErrorSubject.send(.stepCountingNotAvailable)
            return
        }

        // 2. 모션 권한 확인 (iOS 11+에서는 자동으로 권한 요청)
        guard CMPedometer.authorizationStatus() != .denied else {
            pedometerErrorSubject.send(.permissionDenied)
            return
        }

        // 3. 걸음 수 업데이트 시작
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self else { return }

            if let error = error {
                self.handleError(error)
                return
            }

            guard let data = data else { return }

            // 걸음 수 방출
            if let steps = data.numberOfSteps as? Int {
                self.stepCountSubject.send(steps)
            }

            // 거리 방출 (미터를 km로 변환)
            if let distanceInMeters = data.distance as? Double {
                let distanceInKm = distanceInMeters / 1000.0
                self.distanceSubject.send(distanceInKm)
            }
        }
    }

    /// 걸음 수 추적 중지
    func stopTracking() {
        pedometer.stopUpdates()
    }

    /// 특정 기간의 걸음 수 조회
    /// - Parameters:
    ///   - start: 조회 시작 시간
    ///   - end: 조회 종료 시간
    ///   - completion: 결과 콜백 (걸음 수, 거리 km)
    func queryStepCount(
        from start: Date,
        to end: Date,
        completion: @escaping (Result<(steps: Int, distance: Double?), PedometerError>) -> Void
    ) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(.failure(.stepCountingNotAvailable))
            return
        }

        pedometer.queryPedometerData(from: start, to: end) { data, error in
            if let error = error {
                let pedometerError = self.mapError(error)
                completion(.failure(pedometerError))
                return
            }

            guard let data = data else {
                completion(.failure(.unknown))
                return
            }

            let steps = data.numberOfSteps.intValue
            let distanceInKm = data.distance.map { $0.doubleValue / 1000.0 }

            completion(.success((steps: steps, distance: distanceInKm)))
        }
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        let pedometerError = mapError(error)
        pedometerErrorSubject.send(pedometerError)
    }

    private func mapError(_ error: Error) -> PedometerError {
        let cmError = error as NSError

        switch cmError.code {
        case Int(CMErrorMotionActivityNotAuthorized.rawValue):
            return .permissionDenied

        case Int(CMErrorMotionActivityNotAvailable.rawValue):
            return .stepCountingNotAvailable

        case Int(CMErrorMotionActivityNotEntitled.rawValue):
            return .notEntitled

        default:
            return .unknown
        }
    }
}

// MARK: - PedometerError

enum PedometerError: LocalizedError {
    case stepCountingNotAvailable
    case permissionDenied
    case notEntitled
    case unknown

    var errorDescription: String? {
        switch self {
        case .stepCountingNotAvailable:
            return "걸음 수 추적 기능을 사용할 수 없습니다."

        case .permissionDenied:
            return "모션 및 피트니스 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."

        case .notEntitled:
            return "이 기능을 사용할 수 있는 권한이 없습니다."

        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
