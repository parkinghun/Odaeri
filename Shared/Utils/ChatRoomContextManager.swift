//
//  ChatRoomContextManager.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation

final class ChatRoomContextManager {
    static let shared = ChatRoomContextManager()

    private init() {}

    private(set) var currentRoomId: String?

    func enter(roomId: String) {
        currentRoomId = roomId
    }

    func leave(roomId: String) {
        if currentRoomId == roomId {
            currentRoomId = nil
        }
    }
}
