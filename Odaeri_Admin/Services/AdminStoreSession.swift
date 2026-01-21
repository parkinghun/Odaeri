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

    var storeId: String? {
        get { defaults.string(forKey: Key.storeId) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.storeId)
            } else {
                defaults.removeObject(forKey: Key.storeId)
            }
        }
    }

    func clearStoreId() {
        storeId = nil
    }
}
