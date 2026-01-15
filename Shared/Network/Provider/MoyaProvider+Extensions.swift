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
    func request<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval = 10
    ) async throws -> T {
        try await AuthInterceptor.shared.executeWithAuth {
            try await self.performRequest(target, timeout: timeout)
        }
    }

    func request(
        _ target: Target,
        timeout: TimeInterval = 10
    ) async throws {
        try await AuthInterceptor.shared.executeWithAuth {
            try await self.performVoidRequest(target, timeout: timeout)
        }
    }

    func requestWithProgress<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval = 10,
        progress: @escaping (Double) -> Void
    ) async throws -> T {
        try await AuthInterceptor.shared.executeWithAuth {
            try await self.performRequestWithProgress(target, timeout: timeout, progress: progress)
        }
    }

    private func performRequest<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval
    ) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noInternetConnection
        }

        print("========== ASYNC REQUEST DEBUG ==========")
        print("BaseURL: \(target.baseURL)")
        print("Path: \(target.path)")
        print("Method: \(target.method)")
        print("Headers: \(target.headers ?? [:])")
        print("Task: \(target.task)")
        print("=========================================")

        return try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    print("========== ASYNC RESPONSE DEBUG ==========")
                    print("Status Code: \(response.statusCode)")
                    print("Response Headers: \(response.response?.allHeaderFields ?? [:])")
                    print("==========================================")

                    print("========== SERVER ERROR BODY ==========")
                    if let body = String(data: response.data, encoding: .utf8) {
                        print(body)
                    }
                    print("=======================================")

                    if let error = self.parseError(from: response) {
                        continuation.resume(throwing: error)
                        return
                    }

                    do {
                        let decoded = try response.map(T.self)
                        continuation.resume(returning: decoded)
                    } catch {
                        print("Decoding Error: \(error)")
                        continuation.resume(throwing: NetworkError.decodingFailed(error))
                    }

                case .failure(let error):
                    continuation.resume(throwing: self.handleMoyaError(error))
                }
            }
        }
    }

    private func performVoidRequest(
        _ target: Target,
        timeout: TimeInterval
    ) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noInternetConnection
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    if let error = self.parseError(from: response) {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume()

                case .failure(let error):
                    continuation.resume(throwing: self.handleMoyaError(error))
                }
            }
        }
    }

    private func performRequestWithProgress<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval,
        progress: @escaping (Double) -> Void
    ) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noInternetConnection
        }

        print("========== ASYNC PROGRESS REQUEST DEBUG ==========")
        print("BaseURL: \(target.baseURL)")
        print("Path: \(target.path)")
        print("Method: \(target.method)")
        print("Headers: \(target.headers ?? [:])")
        print("Task: \(target.task)")
        print("==================================================")

        return try await withCheckedThrowingContinuation { continuation in
            self.request(
                target,
                callbackQueue: nil,
                progress: { response in
                    progress(response.progress)
                },
                completion: { result in
                    switch result {
                    case .success(let response):
                        print("========== ASYNC PROGRESS RESPONSE DEBUG ==========")
                        print("Status Code: \(response.statusCode)")
                        print("Response Headers: \(response.response?.allHeaderFields ?? [:])")
                        print("===================================================")

                        print("========== SERVER ERROR BODY ==========")
                        if let body = String(data: response.data, encoding: .utf8) {
                            print(body)
                        }
                        print("=======================================")

                        if let error = self.parseError(from: response) {
                            continuation.resume(throwing: error)
                            return
                        }

                        do {
                            let decoded = try response.map(T.self)
                            continuation.resume(returning: decoded)
                        } catch {
                            print("Decoding Error: \(error)")
                            continuation.resume(throwing: NetworkError.decodingFailed(error))
                        }

                    case .failure(let error):
                        continuation.resume(throwing: self.handleMoyaError(error))
                    }
                }
            )
        }
    }

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

                print("========== SERVER ERROR BODY ==========")
                if let body = String(data: response.data, encoding: .utf8) {
                    print(body) // 서버가 보내준 실제 JSON 전문 출력
                }
                print("=======================================")
                
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
                    NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
                    return Fail(error: error).eraseToAnyPublisher()

                case .unauthorized:
                    NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
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

    func requestPublisherWithProgress<T: Decodable>(
        _ target: Target,
        timeout: TimeInterval = 10,
        progress: @escaping (Double) -> Void
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

        let requestPublisher = Deferred {
            Future<Response, NetworkError> { promise in
                self.request(
                    target,
                    callbackQueue: nil,
                    progress: { response in
                        progress(response.progress)
                    },
                    completion: { result in
                        switch result {
                        case .success(let response):
                            promise(.success(response))
                        case .failure(let error):
                            promise(.failure(self.handleMoyaError(error)))
                        }
                    }
                )
            }
        }
        .eraseToAnyPublisher()

        return requestPublisher
            .flatMap { response -> AnyPublisher<T, NetworkError> in
                print("========== RESPONSE DEBUG ==========")
                print("Status Code: \(response.statusCode)")
                print("Response Headers: \(response.response?.allHeaderFields ?? [:])")
                print("====================================")

                print("========== SERVER ERROR BODY ==========")
                if let body = String(data: response.data, encoding: .utf8) {
                    print(body)
                }
                print("=======================================")

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
                    NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
                    return Fail(error: error).eraseToAnyPublisher()

                case .unauthorized:
                    NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
                    return Fail(error: error).eraseToAnyPublisher()

                case .accessTokenExpired:
                    return self.handleTokenRefresh()
                        .flatMap { _ in
                            self.requestPublisherWithProgress(
                                target,
                                timeout: timeout,
                                progress: progress
                            )
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

        if statusCode == 418 {
            return .refreshTokenExpired
        }

        if statusCode == 401 {
            return .unauthorized
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

                    let finalError: NetworkError
                    if case .unauthorized = error {
                        finalError = .invalidRefreshToken
                    } else {
                        finalError = error
                    }

                    return Fail(error: finalError).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}
