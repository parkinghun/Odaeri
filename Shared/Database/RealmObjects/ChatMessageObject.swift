//
//  ChatMessageObject.swift
//  Odaeri
//
//  Created by 박성훈 on 1/11/26.
//

import Foundation
import RealmSwift

enum ChatMessageStatus: String {
    case sending
    case sent
    case error
}

final class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted(indexed: true) var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: String
    @Persisted(indexed: true) var createdAtDate: Date
    @Persisted var updatedAt: String
    @Persisted var sender: ChatParticipantObject?
    @Persisted var files: List<String>
    @Persisted private var statusRaw: String
    @Persisted var isRead: Bool

    var status: ChatMessageStatus {
        get {
            return ChatMessageStatus(rawValue: statusRaw) ?? .sent
        }
        set {
            statusRaw = newValue.rawValue
        }
    }

    convenience init(
        chatId: String,
        roomId: String,
        content: String,
        createdAt: String,
        createdAtDate: Date,
        updatedAt: String,
        sender: ChatParticipantObject?,
        files: [String],
        status: ChatMessageStatus = .sent,
        isRead: Bool = false
    ) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.createdAtDate = createdAtDate
        self.updatedAt = updatedAt
        self.sender = sender
        self.files.append(objectsIn: files)
        self.statusRaw = status.rawValue
        self.isRead = isRead
    }
}

// MARK: - ChatMessageObject Extension
extension ChatMessageObject {
    static func from(entity: ChatEntity, isRead: Bool = false) -> ChatMessageObject? {
        guard let createdAtDate = DateFormatter.iso8601.date(from: entity.createdAt) else {
            print("날짜 파싱 실패: \(entity.createdAt)")
            return nil
        }

        let object = ChatMessageObject()
        object.chatId = entity.chatId
        object.roomId = entity.roomId
        object.content = entity.content
        object.createdAt = entity.createdAt
        object.createdAtDate = createdAtDate
        object.updatedAt = entity.updatedAt
        object.sender = ChatParticipantObject.from(entity: entity.sender)
        object.files.append(objectsIn: entity.files)
        object.statusRaw = ChatMessageStatus.sent.rawValue
        object.isRead = isRead

        return object
    }

    func toEntity() -> ChatEntity {
        return ChatEntity(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender?.toEntity() ?? ChatParticipantEntity(
                userId: "",
                nick: "알 수 없음",
                profileImage: ""
            ),
            files: Array(files)
        )
    }
}
