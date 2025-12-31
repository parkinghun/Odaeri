//
//  TokenManager.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation
import Combine

final class TokenManager {
    static let shared = TokenManager()

    private init() {}

    private var refreshPublisher: AnyPublisher<Void, NetworkError>?
    private let refreshLock = NSLock()

    private let keychain = KeychainManager.shared

    private enum TokenKey: String {
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
        case deviceToken = "deviceToken"
    }

    var accessToken: String? {
        get { try? keychain.get(for: TokenKey.accessToken.rawValue) }
        set {
            if let token = newValue {
                try? keychain.save(token, for: TokenKey.accessToken.rawValue)
            } else {
                try? keychain.delete(for: TokenKey.accessToken.rawValue)
            }
        }
    }

    var refreshToken: String? {
        get { try? keychain.get(for: TokenKey.refreshToken.rawValue) }
        set {
            if let token = newValue {
                try? keychain.save(token, for: TokenKey.refreshToken.rawValue)
            } else {
                try? keychain.delete(for: TokenKey.refreshToken.rawValue)
            }
        }
    }

    var deviceToken: String? {
        get { try? keychain.get(for: TokenKey.deviceToken.rawValue) }
        set {
            if let token = newValue {
                try? keychain.save(token, for: TokenKey.deviceToken.rawValue)
            } else {
                try? keychain.delete(for: TokenKey.deviceToken.rawValue)
            }
        }
    }

    var isLoggedIn: Bool {
        return accessToken != nil && refreshToken != nil
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        UserManager.shared.clearUser()
    }

    func clearAllTokens() {
        try? keychain.deleteAll()
        UserManager.shared.clearUser()
    }

    func getOrCreateRefreshPublisher(
        _ refreshBlock: @escaping () -> AnyPublisher<Void, NetworkError>
    ) -> AnyPublisher<Void, NetworkError> {
        refreshLock.lock()
        defer { refreshLock.unlock() }

        if let existingPublisher = refreshPublisher {
            print("[TokenManager] Reusing existing refresh publisher")
            return existingPublisher
        }

        print("[TokenManager] Creating new refresh publisher")
        let newPublisher = refreshBlock()
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.refreshLock.lock()
                    self?.refreshPublisher = nil
                    self?.refreshLock.unlock()
                    print("[TokenManager] Refresh publisher completed, cleared")
                },
                receiveCancel: { [weak self] in
                    self?.refreshLock.lock()
                    self?.refreshPublisher = nil
                    self?.refreshLock.unlock()
                    print("[TokenManager] Refresh publisher cancelled, cleared")
                }
            )
            .share()
            .eraseToAnyPublisher()

        refreshPublisher = newPublisher
        return newPublisher
    }
}
