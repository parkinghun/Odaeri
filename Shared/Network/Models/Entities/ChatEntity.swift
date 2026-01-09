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

    init(from response: ChatRoomResponse) {
        self.roomId = response.roomId
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
        self.participants = response.participants.map { ChatParticipantEntity(from: $0) }
        self.lastChat = response.lastChat.map { ChatEntity(from: $0) }
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

    init(
        chatId: String,
        roomId: String,
        content: String,
        createdAt: String,
        updatedAt: String,
        sender: ChatParticipantEntity,
        files: [String]
    ) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.files = files
    }

    init(from response: ChatResponse) {
        self.chatId = response.chatId
        self.roomId = response.roomId
        self.content = response.content
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
        self.sender = ChatParticipantEntity(from: response.sender)
        self.files = response.files
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
        profileImage: String
    ) {
        self.userId = userId
        self.nick = nick
        self.profileImage = profileImage
    }

    init(from participant: ChatParticipant) {
        self.userId = participant.userId
        self.nick = participant.nick
        self.profileImage = participant.profileImage
    }
}
