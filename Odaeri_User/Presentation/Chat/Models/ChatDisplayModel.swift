//
//  ChatDisplayModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct ChatDisplayModel: Hashable {
    let id: String
    let content: String
    let createdAt: Date
    let timeText: String
    let senderName: String
    let senderProfileImageUrl: String?
    let hasFiles: Bool
    let files: [String]
    let contents: [ChatMessageContent]

    let senderType: SenderType
    let groupPosition: MessageGroupPosition

    var showProfile: Bool {
        return senderType.needsProfileLayout && groupPosition.showsProfile
    }

    var showName: Bool {
        return senderType.needsProfileLayout && groupPosition.showsName
    }

    var showTime: Bool {
        return groupPosition.showsTime
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatDisplayModel, rhs: ChatDisplayModel) -> Bool {
        return lhs.id == rhs.id
    }
}
