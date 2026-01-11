//
//  ChatRoomMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct ChatRoomMapper {
    static func map(_ entities: [ChatRoomEntity], currentUserId: String) -> [ChatRoomDisplayModel] {
        return entities.map { entity in
            let opponent = entity.participants.first { $0.userId != currentUserId }

            let lastChatText: String
            if let lastChat = entity.lastChat {
                if lastChat.hasFiles {
                    lastChatText = "사진"
                } else if lastChat.content.isEmpty {
                    lastChatText = ""
                } else {
                    lastChatText = lastChat.content
                }
            } else {
                lastChatText = "대화를 시작해보세요"
            }

            let lastChatTimeText: String
            if let lastChat = entity.lastChat,
               let lastChatDate = DateFormatter.iso8601.date(from: lastChat.createdAt) {
                lastChatTimeText = formatChatRoomTime(lastChatDate)
            } else {
                lastChatTimeText = ""
            }

            return ChatRoomDisplayModel(
                roomId: entity.roomId,
                opponentName: opponent?.nick ?? "알 수 없음",
                opponentProfileImageUrl: opponent?.profileImage,
                lastChatText: lastChatText,
                lastChatTimeText: lastChatTimeText,
                unreadCount: 0,
                hasUnread: false
            )
        }
    }

    private static func formatChatRoomTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return DateFormatter.timeDisplay.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return DateFormatter.monthDay.string(from: date)
        } else {
            return DateFormatter.dotDate.string(from: date)
        }
    }
}
