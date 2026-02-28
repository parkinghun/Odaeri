//
//  ChatDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 2/28/26.
//

import Foundation

enum ChatDTOMapper {
    static func toEntity(_ response: ChatRoomResponse) -> ChatRoomEntity {
        ChatRoomEntity(
            roomId: response.roomId,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            participants: response.participants.map(toEntity),
            lastChat: response.lastChat.map(toEntity)
        )
    }

    static func toEntity(_ response: ChatResponse) -> ChatEntity {
        ChatEntity(
            chatId: response.chatId,
            roomId: response.roomId,
            content: response.content,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            sender: toEntity(response.sender),
            files: response.files,
            status: .sent,
            uploadProgress: nil
        )
    }

    static func toEntity(_ participant: ChatParticipant) -> ChatParticipantEntity {
        ChatParticipantEntity(
            userId: participant.userId,
            nick: participant.nick,
            profileImage: participant.profileImage
        )
    }
}
