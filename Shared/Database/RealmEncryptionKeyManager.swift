//
//  RealmEncryptionKeyManager.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import Security

protocol RealmEncryptionKeyManaging {
    func encryptionKey(for userId: String) throws -> Data
    func deleteKey(for userId: String) throws
}

enum RealmEncryptionKeyError: Error {
    case invalidKeyData
    case randomGenerationFailed(status: OSStatus)
}

final class RealmEncryptionKeyManager: RealmEncryptionKeyManaging {
    private let keychain: KeychainManager

    init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
    }

    func encryptionKey(for userId: String) throws -> Data {
        let key = keychainKey(for: userId)

        do {
            let base64 = try keychain.get(for: key)
            guard let data = Data(base64Encoded: base64), data.count == 64 else {
                throw RealmEncryptionKeyError.invalidKeyData
            }
            return data
        } catch KeychainError.itemNotFound {
            let data = try generateKeyData()
            try keychain.save(data.base64EncodedString(), for: key)
            return data
        }
    }

    func deleteKey(for userId: String) throws {
        try keychain.delete(for: keychainKey(for: userId))
    }

    private func keychainKey(for userId: String) -> String {
        "realm.encryptionKey.\(userId)"
    }

    private func generateKeyData() throws -> Data {
        var data = Data(count: 64)
        let status = data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return errSecParam
            }
            return SecRandomCopyBytes(kSecRandomDefault, 64, baseAddress)
        }

        guard status == errSecSuccess else {
            throw RealmEncryptionKeyError.randomGenerationFailed(status: status)
        }

        return data
    }
}

