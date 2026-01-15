//
//  AuthInterceptor.swift
//  Odaeri
//
//  Created by 박성훈 on 1/15/26.
//

import Foundation
import Moya

actor AuthInterceptor {
    typealias AsyncTask = _Concurrency.Task

    static let shared = AuthInterceptor()

    private enum RefreshState {
        case idle
        case refreshing(AsyncTask<Result<Void, Error>, Never>)
    }

    private var refreshState: RefreshState = .idle
    private var waitingContinuations: [CheckedContinuation<Void, Error>] = []

    private init() {}

    func executeWithAuth<T>(_ operation: () async throws -> T) async throws -> T {
        await waitForRefreshIfNeeded()

        do {
            return try await operation()
        } catch let error as NetworkError {
            if case .accessTokenExpired = error {
                try await refreshToken()
                return try await operation()
            }
            throw error
        } catch {
            throw error
        }
    }

    private func waitForRefreshIfNeeded() async {
        switch refreshState {
        case .idle:
            return

        case .refreshing:
            print("[AuthInterceptor] Request is waiting for token refresh to complete")

            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    waitingContinuations.append(continuation)
                }
            } catch {
                print("[AuthInterceptor] Refresh failed for waiting request: \(error)")
            }
        }
    }

    func refreshToken() async throws {
        switch refreshState {
        case .refreshing(let task):
            print("[AuthInterceptor] Refresh already in progress, waiting...")
            let result = await task.value
            switch result {
            case .success:
                return
            case .failure(let error):
                throw error
            }

        case .idle:
            print("[AuthInterceptor] Starting token refresh")

            let refreshTask = AsyncTask { () -> Result<Void, Error> in
                do {
                    try await performTokenRefresh()
                    resumeAllWaitingRequests(with: .success(()))
                    return .success(())
                } catch {
                    resumeAllWaitingRequests(with: .failure(error))
                    return .failure(error)
                }
            }

            refreshState = .refreshing(refreshTask)

            let result = await refreshTask.value
            refreshState = .idle

            switch result {
            case .success:
                print("[AuthInterceptor] Token refresh completed successfully")
            case .failure(let error):
                print("[AuthInterceptor] Token refresh failed: \(error)")
                throw error
            }
        }
    }

    private func performTokenRefresh() async throws {
        guard let refreshToken = TokenManager.shared.refreshToken else {
            TokenManager.shared.clearTokens()
            let error = NetworkError.refreshTokenExpired
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
            throw error
        }

        let authProvider = MoyaProvider<AuthAPI>(plugins: [])

        do {
            let response: RefreshTokenResponse = try await authProvider.request(AuthAPI.refreshToken)

            TokenManager.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            print("[AuthInterceptor] Tokens updated successfully")

        } catch let error as NetworkError {
            TokenManager.shared.clearTokens()

            let finalError: NetworkError
            switch error {
            case .unauthorized:
                finalError = .invalidRefreshToken
                NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)

            case .refreshTokenExpired:
                finalError = .refreshTokenExpired
                NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)

            default:
                finalError = error
            }

            throw finalError

        } catch {
            TokenManager.shared.clearTokens()
            throw NetworkError.unknown(error)
        }
    }

    private func resumeAllWaitingRequests(with result: Result<Void, Error>) {
        let continuations = waitingContinuations
        waitingContinuations.removeAll()

        print("[AuthInterceptor] Resuming \(continuations.count) waiting requests")

        for continuation in continuations {
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
