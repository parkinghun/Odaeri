//
//  ChatDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation

// MARK: - Request Models

struct CreateChatRoomRequest: Encodable {
    let opponentId: String

    enum CodingKeys: String, CodingKey {
        case opponentId = "opponent_id"
    }
}

struct SendChatRequest: Encodable {
    let content: String
    let files: [String]
}

// MARK: - Response Models

struct ChatRoomResponse: Decodable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatParticipant]
    let lastChat: ChatResponse?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt, updatedAt
        case participants
        case lastChat
    }
}

struct ChatRoomListResponse: Decodable {
    let data: [ChatRoomResponse]
}

struct ChatResponse: Decodable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatParticipant
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content, createdAt, updatedAt
        case sender, files
    }
}

struct ChatListResponse: Decodable {
    let data: [ChatResponse]
}

struct ChatFileUploadResponse: Decodable {
    let files: [String]
}

struct ChatParticipant: Decodable {
    let userId: String
    let nick: String
    let profileImage: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}
