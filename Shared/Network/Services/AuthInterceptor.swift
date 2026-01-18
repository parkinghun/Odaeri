//
//  AuthInterceptor.swift
//  Odaeri
//
//  Created by 박성훈 on 1/15/26.
//

import Foundation
import Moya
import Combine

actor AuthInterceptor {
    static let shared = AuthInterceptor()

    private init() {}

    func executeWithAuth<T>(_ operation: () async throws -> T) async throws -> T {
        try await TokenRefreshCoordinator.shared.waitIfRefreshing()

        do {
            return try await operation()
        } catch let error as NetworkError {
            if case .accessTokenExpired = error {
                try await refreshTokenUsingCoordinator()
                return try await operation()
            }
            throw error
        } catch {
            throw error
        }
    }

    private func refreshTokenUsingCoordinator() async throws {
        print("[AuthInterceptor] Starting token refresh via TokenRefreshCoordinator")

        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var didResume = false

            cancellable = TokenRefreshCoordinator.shared.refresh()
                .sink(
                    receiveCompletion: { completion in
                        guard !didResume else { return }
                        didResume = true

                        switch completion {
                        case .finished:
                            print("[AuthInterceptor] Token refresh completed successfully")
                            continuation.resume()
                        case .failure(let error):
                            print("[AuthInterceptor] Token refresh failed: \(error)")
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { _ in }
                )
        }
    }
}
