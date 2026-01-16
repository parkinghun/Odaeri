//
//  DeviceIdManager.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation
import UIKit

final class DeviceIdManager {
    static let shared = DeviceIdManager()

    private let storageKey = "com.odaeri.deviceId"

    private init() {}

    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: storageKey) {
            return existing
        }

        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.setValue(newId, forKey: storageKey)
        return newId
    }
}
