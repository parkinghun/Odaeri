//
//  AdminStoreSession.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

final class AdminStoreSession {
    static let shared = AdminStoreSession()

    private enum Key {
        static let storeId = "adminStoreId"
    }

    private let defaults = UserDefaults.standard
    private let keychain = KeychainManager.shared

    var storeId: String? {
        get {
            guard let userId = UserManager.shared.currentUserId else { return nil }
            let key = userScopedKey(for: userId)
            if let stored = try? keychain.get(for: key) {
                return stored
            }
            if let legacy = defaults.string(forKey: Key.storeId) {
                try? keychain.save(legacy, for: key)
                defaults.removeObject(forKey: Key.storeId)
                return legacy
            }
            return nil
        }
        set {
            guard let userId = UserManager.shared.currentUserId else { return }
            let key = userScopedKey(for: userId)
            if let newValue {
                try? keychain.save(newValue, for: key)
            } else {
                try? keychain.delete(for: key)
            }
        }
    }

    func clearStoreId() {
        storeId = nil
    }

    private func userScopedKey(for userId: String) -> String {
        "\(Key.storeId).\(userId)"
    }
}
