//
//  ChatRoomDisplayModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct ChatRoomDisplayModel: Hashable {
    let roomId: String
    let opponentName: String
    let opponentProfileImageUrl: String?
    let lastChatText: String
    let lastChatTimeText: String
    let unreadCount: Int
    let hasUnread: Bool

    var unreadBadgeText: String {
        if unreadCount > 99 {
            return "99+"
        }
        return "\(unreadCount)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(roomId)
    }

    static func == (lhs: ChatRoomDisplayModel, rhs: ChatRoomDisplayModel) -> Bool {
        return lhs.roomId == rhs.roomId
    }
}
