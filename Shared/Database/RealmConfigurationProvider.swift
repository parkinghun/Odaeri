//
//  RealmConfigurationProvider.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import RealmSwift

protocol RealmConfigurationProviding {
    func configuration(for userId: String) throws -> Realm.Configuration
    func realmDirectory(for userId: String) throws -> URL
    func deleteRealmDirectory(for userId: String) throws
}

enum RealmConfigurationError: Error {
    case documentsDirectoryNotFound
}

final class RealmConfigurationProvider: RealmConfigurationProviding {
    private let keyManager: RealmEncryptionKeyManaging
    private let fileManager: FileManager
    private let schemaVersion: UInt64 = 1

    init(
        keyManager: RealmEncryptionKeyManaging = RealmEncryptionKeyManager(),
        fileManager: FileManager = .default
    ) {
        self.keyManager = keyManager
        self.fileManager = fileManager
    }

    func configuration(for userId: String) throws -> Realm.Configuration {
        let realmURL = try realmFileURL(for: userId)
        let key = try keyManager.encryptionKey(for: userId)

        return Realm.Configuration(
            fileURL: realmURL,
            encryptionKey: key,
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: ChatRoomObject.className()) { _, newObject in
                        newObject?["hasUnread"] = false
                    }
                }
            }
        )
    }

    func realmDirectory(for userId: String) throws -> URL {
        let documentsURL = try documentsDirectory()
        let userDirectory = documentsURL.appendingPathComponent("Users").appendingPathComponent(userId)
        let realmDirectory = userDirectory.appendingPathComponent("Realm")

        if !fileManager.fileExists(atPath: realmDirectory.path) {
            try fileManager.createDirectory(
                at: realmDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return realmDirectory
    }

    func deleteRealmDirectory(for userId: String) throws {
        let documentsURL = try documentsDirectory()
        let userDirectory = documentsURL.appendingPathComponent("Users").appendingPathComponent(userId)

        guard fileManager.fileExists(atPath: userDirectory.path) else { return }
        try fileManager.removeItem(at: userDirectory)
    }

    private func realmFileURL(for userId: String) throws -> URL {
        let directory = try realmDirectory(for: userId)
        return directory.appendingPathComponent("default.realm")
    }

    private func documentsDirectory() throws -> URL {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RealmConfigurationError.documentsDirectoryNotFound
        }
        return url
    }
}

