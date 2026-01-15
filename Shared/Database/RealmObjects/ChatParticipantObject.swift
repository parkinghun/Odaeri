//
//  ChatParticipantObject.swift
//  Odaeri
//
//  Created by 박성훈 on 1/11/26.
//

import Foundation
import RealmSwift

final class ChatParticipantObject: EmbeddedObject {
    @Persisted var userId: String
    @Persisted var nick: String
    @Persisted var profileImage: String?

    convenience init(userId: String, nick: String, profileImage: String?) {
        self.init()
        self.userId = userId
        self.nick = nick
        self.profileImage = profileImage
    }
}

extension ChatParticipantObject {
    static func from(entity: ChatParticipantEntity) -> ChatParticipantObject {
        let object = ChatParticipantObject()
        object.userId = entity.userId
        object.nick = entity.nick
        object.profileImage = entity.profileImage
        return object
    }

    func toEntity() -> ChatParticipantEntity {
        return ChatParticipantEntity(
            userId: userId,
            nick: nick,
            profileImage: profileImage ?? ""
        )
    }
}
