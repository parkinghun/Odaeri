//
//  ChatEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation

struct ChatRoomEntity {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatParticipantEntity]
    let lastChat: ChatEntity?

    init(
        roomId: String,
        createdAt: String,
        updatedAt: String,
        participants: [ChatParticipantEntity],
        lastChat: ChatEntity?
    ) {
        self.roomId = roomId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.participants = participants
        self.lastChat = lastChat
    }

}

struct ChatEntity {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatParticipantEntity
    let files: [String]
    let status: ChatMessageStatus
    let uploadProgress: Float?

    init(
        chatId: String,
        roomId: String,
        content: String,
        createdAt: String,
        updatedAt: String,
        sender: ChatParticipantEntity,
        files: [String],
        status: ChatMessageStatus = .sent,
        uploadProgress: Float? = nil
    ) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.files = files
        self.status = status
        self.uploadProgress = uploadProgress
    }

    var hasFiles: Bool {
        return !files.isEmpty
    }
}

struct ChatParticipantEntity {
    let userId: String
    let nick: String
    let profileImage: String?

    init(
        userId: String,
        nick: String,
        profileImage: String?
    ) {
        self.userId = userId
        self.nick = nick
        self.profileImage = profileImage
    }

}
