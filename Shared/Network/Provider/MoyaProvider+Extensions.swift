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

        print("========== REQUEST DEBUG ==========")
        print("BaseURL: \(target.baseURL)")
        print("Path: \(target.path)")
        print("Method: \(target.method)")
        print("Headers: \(target.headers ?? [:])")
        print("Task: \(target.task)")
        print("===================================")

        return self.requestPublisher(target)
            .mapError { self.handleMoyaError($0) }
            .flatMap { response -> AnyPublisher<T, NetworkError> in
                print("========== RESPONSE DEBUG ==========")
                print("Status Code: \(response.statusCode)")
                print("Response Headers: \(response.response?.allHeaderFields ?? [:])")
                print("====================================")

                if let error = self.parseError(from: response) {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                do {
                    let decoded = try response.map(T.self)
                    return Just(decoded)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("Decoding Error: \(error)")
                    return Fail(error: NetworkError.decodingFailed(error))
                        .eraseToAnyPublisher()
                }
            }
            .catch { [weak self] error -> AnyPublisher<T, NetworkError> in
                guard let self = self else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                switch error {
                case .invalidRefreshToken, .refreshTokenExpired:
                    return Fail(error: error).eraseToAnyPublisher()

                case .accessTokenExpired:
                    return self.handleTokenRefresh()
                        .flatMap { _ in
                            self.requestPublisher(target, timeout: timeout)
                        }
                        .eraseToAnyPublisher()

                default:
                    return Fail(error: error).eraseToAnyPublisher()
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
            .catch { [weak self] error -> AnyPublisher<Void, NetworkError> in
                guard let self = self else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                switch error {
                case .invalidRefreshToken, .refreshTokenExpired:
                    return Fail(error: error).eraseToAnyPublisher()

                case .accessTokenExpired:
                    return self.handleTokenRefresh()
                        .flatMap { _ -> AnyPublisher<Void, NetworkError> in
                            self.requestPublisher(target, timeout: timeout)
                        }
                        .eraseToAnyPublisher()

                default:
                    return Fail(error: error).eraseToAnyPublisher()
                }
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

        if statusCode == 401 {
            return .invalidRefreshToken
        }

        if statusCode == 418 {
            return .refreshTokenExpired
        }

        if let errorResponse = try? response.map(ErrorResponse.self) {
            return .serverError(statusCode: statusCode, message: errorResponse.message)
        }

        return .serverError(statusCode: statusCode, message: "알 수 없는 서버 오류")
    }

    private func handleMoyaError(_ moyaError: MoyaError) -> NetworkError {
        switch moyaError {
        case .underlying(let error, let response):
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

            if let response = response, let networkError = parseError(from: response) {
                return networkError
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

    private func handleTokenRefresh() -> AnyPublisher<Void, NetworkError> {
        return TokenManager.shared.getOrCreateRefreshPublisher {
            guard let refreshToken = TokenManager.shared.refreshToken else {
                TokenManager.shared.clearTokens()
                return Fail(error: NetworkError.refreshTokenExpired)
                    .eraseToAnyPublisher()
            }

            let authProvider = MoyaProvider<AuthAPI>(plugins: [])
            let publisher: AnyPublisher<RefreshTokenResponse, NetworkError> = authProvider.requestPublisher(
                AuthAPI.refreshToken
            )

            return publisher
                .flatMap { refreshResponse -> AnyPublisher<Void, NetworkError> in
                    TokenManager.shared.saveTokens(
                        accessToken: refreshResponse.accessToken,
                        refreshToken: refreshResponse.refreshToken
                    )
                    return Just(())
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                .catch { error -> AnyPublisher<Void, NetworkError> in
                    TokenManager.shared.clearTokens()
                    return Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}
