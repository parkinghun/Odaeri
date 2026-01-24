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
    private var refreshTask: _Concurrency.Task<Void, Error>?

    private init() {}

    func resetRetryCount() {
        retryCount = 0
    }

    func waitIfRefreshing() async throws {
        guard isRefreshing else {
            print("[TokenRefreshCoordinator] waitIfRefreshing: Not refreshing, continuing")
            return
        }

        print("[TokenRefreshCoordinator] waitIfRefreshing: Refresh in progress, waiting...")

        return try await withCheckedThrowingContinuation { continuation in
            guard let subject = refreshSubject else {
                print("[TokenRefreshCoordinator] waitIfRefreshing: No subject, resuming")
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
                        print("[TokenRefreshCoordinator] waitIfRefreshing: Refresh completed, resuming")
                        continuation.resume()
                    case .failure(let error):
                        print("[TokenRefreshCoordinator] waitIfRefreshing: Refresh failed, throwing error")
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
            print("[TokenRefreshCoordinator] Already refreshing, waiting for completion...")
            guard let subject = refreshSubject else {
                print("[TokenRefreshCoordinator] ERROR: isRefreshing=true but subject is nil")
                throw NetworkError.unknown(NSError(domain: "TokenRefreshCoordinator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Refresh subject not initialized"]))
            }

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var cancellable: AnyCancellable?
                var didResume = false

                print("[TokenRefreshCoordinator] Subscribing to refresh subject...")
                cancellable = subject
                    .first()
                    .sink { result in
                        guard !didResume else {
                            print("[TokenRefreshCoordinator] Continuation already resumed, ignoring")
                            return
                        }
                        didResume = true

                        switch result {
                        case .success:
                            print("[TokenRefreshCoordinator] Wait completed successfully")
                            promise(.success(()))
                            continuation.resume()
                        case .failure(let error):
                            print("[TokenRefreshCoordinator] Wait completed with error: \(error)")
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
            print("[TokenRefreshCoordinator] Retry limit exceeded (count: \(retryCount))")
            let error = NetworkError.unknown(NSError(domain: "TokenRefreshCoordinator", code: -3, userInfo: [NSLocalizedDescriptionKey: "Token refresh retry limit exceeded"]))
            await completeRefresh(success: false)
            promise(.failure(error))
            throw error
        }

        // 갱신 시작 (subject 먼저 초기화)
        print("[TokenRefreshCoordinator] Starting new refresh (retry: \(retryCount))")
        await startRefresh()
        retryCount += 1

        do {
            try await performTokenRefresh()
            await completeRefresh(success: true)
            retryCount = 0
            print("[TokenRefreshCoordinator] Refresh completed successfully, retry count reset")
            promise(.success(()))
        } catch {
            print("[TokenRefreshCoordinator] Refresh failed: \(error)")
            await completeRefresh(success: false)
            promise(.failure(error))
            throw error
        }
    }

    private func performTokenRefresh() async throws {
        print("[TokenRefreshCoordinator] Starting token refresh...")

        guard let refreshToken = TokenManager.shared.refreshToken else {
            print("[TokenRefreshCoordinator] No refresh token found")
            TokenManager.shared.clearTokens()
            let error = NetworkError.refreshTokenExpired
            throw error
        }

        // AuthAPI는 plugins 없이 직접 호출 (순환 참조 방지)
        let authProvider = MoyaProvider<AuthAPI>(plugins: [])

        do {
            // 직접 Moya의 request 메서드 사용 (AuthInterceptor 우회)
            let response: RefreshTokenResponse = try await withCheckedThrowingContinuation { continuation in
                authProvider.request(AuthAPI.refreshToken) { result in
                    switch result {
                    case .success(let moyaResponse):
                        do {
                            // 상태 코드 체크
                            if moyaResponse.statusCode == 418 {
                                continuation.resume(throwing: NetworkError.refreshTokenExpired)
                                return
                            }
                            if moyaResponse.statusCode == 401 {
                                continuation.resume(throwing: NetworkError.unauthorized)
                                return
                            }
                            if !(200...299).contains(moyaResponse.statusCode) {
                                continuation.resume(throwing: NetworkError.serverError(statusCode: moyaResponse.statusCode, message: "Token refresh failed"))
                                return
                            }

                            let decoded = try moyaResponse.map(RefreshTokenResponse.self)
                            continuation.resume(returning: decoded)
                        } catch {
                            continuation.resume(throwing: NetworkError.decodingFailed(error))
                        }
                    case .failure(let moyaError):
                        continuation.resume(throwing: NetworkError.unknown(moyaError))
                    }
                }
            }

            TokenManager.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            print("[TokenRefreshCoordinator] Tokens updated successfully - AccessToken: \(response.accessToken.prefix(20))...")

        } catch let error as NetworkError {
            print("[TokenRefreshCoordinator] Token refresh failed with NetworkError: \(error)")
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
            print("[TokenRefreshCoordinator] Token refresh failed with error: \(error)")
            TokenManager.shared.clearTokens()
            throw NetworkError.unknown(error)
        }
    }

    private func startRefresh() {
        print("[TokenRefreshCoordinator] startRefresh: Creating subject and setting isRefreshing=true")
        // subject를 먼저 초기화한 후 isRefreshing을 true로 설정
        refreshSubject = PassthroughSubject<Result<Void, Error>, Never>()
        isRefreshing = true
    }

    private func completeRefresh(success: Bool) {
        print("[TokenRefreshCoordinator] completeRefresh: success=\(success)")

        defer {
            print("[TokenRefreshCoordinator] completeRefresh: Cleaning up - isRefreshing=false, subject=nil")
            isRefreshing = false
            refreshSubject = nil
        }

        if success {
            print("[TokenRefreshCoordinator] completeRefresh: Sending success to waiting requests")
            refreshSubject?.send(.success(()))
        } else {
            let error = NetworkError.refreshTokenExpired
            print("[TokenRefreshCoordinator] completeRefresh: Sending failure to waiting requests")
            refreshSubject?.send(.failure(error))

            // 세션 무효화 처리
            _Concurrency.Task { @MainActor in
                print("[TokenRefreshCoordinator] Session invalidated - setting flag and posting notification")
                TokenManager.shared.invalidateSession()
                NotificationCenter.default.post(name: .sessionInvalidated, object: nil)
            }
        }
    }
}
