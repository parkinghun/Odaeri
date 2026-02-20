//
//  ChatSyncAnchorStore.swift
//  Odaeri
//
//  Created by 박성훈 on 2/20/26.
//

import Foundation

protocol ChatSyncAnchorStoring {
    func syncAnchor(roomId: String, userId: String) -> String?
    func setSyncAnchor(_ anchor: String, roomId: String, userId: String)
    func removeSyncAnchor(roomId: String, userId: String)
}

final class ChatSyncAnchorStore: ChatSyncAnchorStoring {
    static let shared = ChatSyncAnchorStore()

    private enum Constant {
        static let keyPrefix = "chat.syncAnchor"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func syncAnchor(roomId: String, userId: String) -> String? {
        return userDefaults.string(forKey: key(roomId: roomId, userId: userId))
    }

    func setSyncAnchor(_ anchor: String, roomId: String, userId: String) {
        userDefaults.set(anchor, forKey: key(roomId: roomId, userId: userId))
    }

    func removeSyncAnchor(roomId: String, userId: String) {
        userDefaults.removeObject(forKey: key(roomId: roomId, userId: userId))
    }

    private func key(roomId: String, userId: String) -> String {
        return "\(Constant.keyPrefix).\(userId).\(roomId)"
    }
}
