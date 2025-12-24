//
//  MoyaProvider+Extensions.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya
import CombineMoya
import Combine

extension MoyaProvider {
    func requestPublisher<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval = 10
    ) -> AnyPublisher<T, NetworkError> {
        guard NetworkMonitor.shared.isConnected else {
            return Fail(error: NetworkError.noInternetConnection)
                .eraseToAnyPublisher()
        }

        return self.requestPublisher(target)
            .mapError { self.handleMoyaError($0) }
            .flatMap { response -> AnyPublisher<T, NetworkError> in
                if let error = self.parseError(from: response) {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                do {
                    let decoded = try response.map(T.self)
                    return Just(decoded)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: NetworkError.decodingFailed(error))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func requestPublisher(
        _ target: Target,
        timeout: TimeInterval = 10
    ) -> AnyPublisher<Void, NetworkError> {
        guard NetworkMonitor.shared.isConnected else {
            return Fail(error: NetworkError.noInternetConnection)
                .eraseToAnyPublisher()
        }

        return self.requestPublisher(target)
            .mapError { self.handleMoyaError($0) }
            .flatMap { response -> AnyPublisher<Void, NetworkError> in
                if let error = self.parseError(from: response) {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return Just(())
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func requestPublisherWithRetry<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval = 10,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) -> AnyPublisher<T, NetworkError> {
        return requestPublisher(target, timeout: timeout)
            .catch { error -> AnyPublisher<T, NetworkError> in
                guard error.isRetryable, retryCount > 0 else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return Just(())
                    .delay(for: .seconds(retryDelay), scheduler: DispatchQueue.main)
                    .flatMap { _ in
                        self.requestPublisherWithRetry(
                            target,
                            timeout: timeout,
                            retryCount: retryCount - 1,
                            retryDelay: retryDelay * 1.5
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func requestPublisherWithRetry(
        _ target: Target,
        timeout: TimeInterval = 10,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) -> AnyPublisher<Void, NetworkError> {
        return requestPublisher(target, timeout: timeout)
            .catch { error -> AnyPublisher<Void, NetworkError> in
                guard error.isRetryable, retryCount > 0 else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return Just(())
                    .delay(for: .seconds(retryDelay), scheduler: DispatchQueue.main)
                    .flatMap { _ in
                        self.requestPublisherWithRetry(
                            target,
                            timeout: timeout,
                            retryCount: retryCount - 1,
                            retryDelay: retryDelay * 1.5
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parseError(from response: Response) -> NetworkError? {
        let statusCode = response.statusCode

        guard !(200...299).contains(statusCode) else {
            return nil
        }

        if statusCode == 419 {
            return .accessTokenExpired
        }

        if let errorResponse = try? response.map(ErrorResponse.self) {
            return .serverError(statusCode: statusCode, message: errorResponse.message)
        }

        return .serverError(statusCode: statusCode, message: "알 수 없는 서버 오류")
    }

    private func handleMoyaError(_ moyaError: MoyaError) -> NetworkError {
        switch moyaError {
        case .underlying(let error, _):
            let nsError = error as NSError

            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost:
                    return .noInternetConnection
                case NSURLErrorTimedOut:
                    return .timeout
                default:
                    break
                }
            }

            return .unknown(error)

        case .statusCode(let response):
            if let networkError = parseError(from: response) {
                return networkError
            }
            return .unknown(moyaError)

        default:
            return .unknown(moyaError)
        }
    }
}
