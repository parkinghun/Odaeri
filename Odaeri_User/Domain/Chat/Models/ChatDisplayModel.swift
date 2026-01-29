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
    let senderUserId: String
    let senderProfileImageUrl: String?
    let hasFiles: Bool
    let files: [String]
    let contents: [ChatMessageContent]
    let status: ChatMessageStatus
    let uploadProgress: Float?

    let senderType: ChatSenderRole
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
        hasher.combine(status.rawValue)
        hasher.combine(uploadProgress)
        hasher.combine(content)
        hasher.combine(files)
        hasher.combine(contents)
        hasher.combine(timeText)
        hasher.combine(senderName)
        hasher.combine(senderProfileImageUrl)
        hasher.combine(senderType)
        hasher.combine(groupPosition)
    }

    static func == (lhs: ChatDisplayModel, rhs: ChatDisplayModel) -> Bool {
        return lhs.id == rhs.id &&
            lhs.status == rhs.status &&
            lhs.uploadProgress == rhs.uploadProgress &&
            lhs.content == rhs.content &&
            lhs.files == rhs.files &&
            lhs.contents == rhs.contents &&
            lhs.timeText == rhs.timeText &&
            lhs.senderName == rhs.senderName &&
            lhs.senderProfileImageUrl == rhs.senderProfileImageUrl &&
            lhs.senderType == rhs.senderType &&
            lhs.groupPosition == rhs.groupPosition
    }
}
