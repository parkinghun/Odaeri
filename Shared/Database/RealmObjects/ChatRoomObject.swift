//
//  ChatRoomObject.swift
//  Odaeri
//
//  Created by 박성훈 on 1/11/26.
//

import Foundation
import RealmSwift

final class ChatRoomObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var createdAt: String
    @Persisted var updatedAt: String
    @Persisted(indexed: true) var updatedAtDate: Date
    @Persisted var participants: List<ChatParticipantObject>
    @Persisted var lastChatContent: String?
    @Persisted var lastChatCreatedAt: String?
    @Persisted(indexed: true) var hasUnread: Bool
    @Persisted var unreadCount: Int

    convenience init(
        roomId: String,
        createdAt: String,
        updatedAt: String,
        updatedAtDate: Date,
        participants: [ChatParticipantObject],
        lastChatContent: String? = nil,
        lastChatCreatedAt: String? = nil,
        hasUnread: Bool = false,
        unreadCount: Int = 0
    ) {
        self.init()
        self.roomId = roomId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.updatedAtDate = updatedAtDate
        self.participants.append(objectsIn: participants)
        self.lastChatContent = lastChatContent
        self.lastChatCreatedAt = lastChatCreatedAt
        self.hasUnread = hasUnread
        self.unreadCount = unreadCount
    }
}

extension ChatRoomObject {
    static func from(entity: ChatRoomEntity) -> ChatRoomObject? {
        guard let updatedAtDate = DateFormatter.iso8601.date(from: entity.updatedAt) else {
            print("날짜 파싱 실패: \(entity.updatedAt)")
            return nil
        }

        let object = ChatRoomObject()
        object.roomId = entity.roomId
        object.createdAt = entity.createdAt
        object.updatedAt = entity.updatedAt
        object.updatedAtDate = updatedAtDate

        let participantObjects = entity.participants.map { participant in
            ChatParticipantObject.from(entity: participant)
        }
        object.participants.append(objectsIn: participantObjects)

        if let lastChat = entity.lastChat {
            object.lastChatContent = lastChat.content
            object.lastChatCreatedAt = lastChat.createdAt
        }

        object.hasUnread = false
        object.unreadCount = 0

        return object
    }

    func toEntity() -> ChatRoomEntity {
        // Realm List를 Array로 변환
        let participantEntities = Array(participants.map { $0.toEntity() })

        let lastChatEntity: ChatEntity?
        if let content = lastChatContent,
           let createdAt = lastChatCreatedAt {
            lastChatEntity = ChatEntity(
                chatId: "",
                roomId: roomId,
                content: content,
                createdAt: createdAt,
                updatedAt: createdAt,
                sender: participantEntities.first ?? ChatParticipantEntity(
                    userId: "",
                    nick: "알 수 없음",
                    profileImage: ""
                ),
                files: []
            )
        } else {
            lastChatEntity = nil
        }

        return ChatRoomEntity(
            roomId: roomId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            participants: participantEntities,
            lastChat: lastChatEntity
        )
    }
}
