//
//  TokenRefreshCoordinator.swift
//  Odaeri
//
//  Created by 박성훈 on 01/18/26.
//

import Foundation
import Combine
import Moya

actor TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()

    private var isRefreshing = false
    private var refreshSubject: PassthroughSubject<Result<Void, Error>, Never>?
    private var retryCount = 0
    private let maxRetryCount = 1

    private init() {}

    func waitIfRefreshing() async throws {
        guard isRefreshing else { return }

        return try await withCheckedThrowingContinuation { continuation in
            guard let subject = refreshSubject else {
                continuation.resume()
                return
            }

            var cancellable: AnyCancellable?
            var didResume = false

            cancellable = subject
                .first()
                .sink { result in
                    guard !didResume else { return }
                    didResume = true

                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                }
        }
    }

    nonisolated func refresh() -> AnyPublisher<Void, Error> {
        return Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(NetworkError.unknown(NSError(domain: "TokenRefreshCoordinator", code: -1, userInfo: [NSLocalizedDescriptionKey: "TokenRefreshCoordinator deallocated"]))))
                    return
                }

                _Concurrency.Task {
                    do {
                        try await self.performRefresh(promise: promise)
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    private func performRefresh(promise: @escaping (Result<Void, Error>) -> Void) async throws {
        // 이미 갱신 중이면 대기
        if isRefreshing {
            guard let subject = refreshSubject else {
                throw NetworkError.unknown(NSError(domain: "TokenRefreshCoordinator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Refresh subject not initialized"]))
            }

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var cancellable: AnyCancellable?
                var didResume = false

                cancellable = subject
                    .first()
                    .sink { result in
                        guard !didResume else { return }
                        didResume = true

                        switch result {
                        case .success:
                            promise(.success(()))
                            continuation.resume()
                        case .failure(let error):
                            promise(.failure(error))
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    }
            }
            return
        }

        // 재시도 제한 확인
        if retryCount >= maxRetryCount {
            let error = NetworkError.unknown(NSError(domain: "TokenRefreshCoordinator", code: -3, userInfo: [NSLocalizedDescriptionKey: "Token refresh retry limit exceeded"]))
            await completeRefresh(success: false)
            promise(.failure(error))
            throw error
        }

        // 갱신 시작 (subject 먼저 초기화)
        await startRefresh()
        retryCount += 1

        do {
            try await performTokenRefresh()
            await completeRefresh(success: true)
            retryCount = 0
            promise(.success(()))
        } catch {
            await completeRefresh(success: false)
            promise(.failure(error))
            throw error
        }
    }

    private func performTokenRefresh() async throws {
        guard let refreshToken = TokenManager.shared.refreshToken else {
            TokenManager.shared.clearTokens()
            let error = NetworkError.refreshTokenExpired
            throw error
        }

        let authProvider = MoyaProvider<AuthAPI>(plugins: [])

        do {
            let response: RefreshTokenResponse = try await authProvider.request(AuthAPI.refreshToken)

            TokenManager.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            print("[TokenRefreshCoordinator] Tokens updated successfully")

        } catch let error as NetworkError {
            TokenManager.shared.clearTokens()

            let finalError: NetworkError
            switch error {
            case .unauthorized:
                finalError = .invalidRefreshToken

            case .refreshTokenExpired:
                finalError = .refreshTokenExpired

            default:
                finalError = error
            }

            throw finalError

        } catch {
            TokenManager.shared.clearTokens()
            throw NetworkError.unknown(error)
        }
    }

    private func startRefresh() {
        // subject를 먼저 초기화한 후 isRefreshing을 true로 설정
        refreshSubject = PassthroughSubject<Result<Void, Error>, Never>()
        isRefreshing = true
    }

    private func completeRefresh(success: Bool) {
        defer {
            isRefreshing = false
            refreshSubject = nil
        }

        if success {
            refreshSubject?.send(.success(()))
        } else {
            let error = NetworkError.refreshTokenExpired
            refreshSubject?.send(.failure(error))

            // 로그아웃 처리
            _Concurrency.Task { @MainActor in
                TokenManager.shared.clearTokens()
                NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
            }
        }
    }
}
