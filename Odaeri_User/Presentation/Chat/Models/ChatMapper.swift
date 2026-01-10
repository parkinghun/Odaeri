//
//  ChatMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct ChatMapper {
    static func map(_ entities: [ChatEntity], currentUserId: String) -> [ChatItem] {
        guard !entities.isEmpty else { return [] }

        let dates = entities.compactMap { DateFormatter.iso8601.date(from: $0.createdAt) }
        guard dates.count == entities.count else { return [] }

        var result: [ChatItem] = []

        for (index, entity) in entities.enumerated() {
            let createdAt = dates[index]
            let previousDate = index > 0 ? dates[index - 1] : nil
            let nextDate = index < dates.count - 1 ? dates[index + 1] : nil

            if shouldInsertDateSeparator(current: createdAt, previous: previousDate) {
                let dateText = formatDateSeparator(createdAt)
                result.append(.dateSeparator(dateText))
            }

            let previous = index > 0 ? entities[index - 1] : nil
            let next = index < entities.count - 1 ? entities[index + 1] : nil

            let senderType: SenderType = entity.sender.userId == currentUserId ? .me : .other
            let groupPosition = determineGroupPosition(
                current: entity,
                currentDate: createdAt,
                previous: previous,
                previousDate: previousDate,
                next: next,
                nextDate: nextDate
            )

            let displayModel = ChatDisplayModel(
                id: entity.chatId,
                content: entity.content,
                createdAt: createdAt,
                timeText: DateFormatter.timeDisplay.string(from: createdAt),
                senderName: entity.sender.nick,
                senderProfileImageUrl: entity.sender.profileImage,
                hasFiles: entity.hasFiles,
                files: entity.files,
                senderType: senderType,
                groupPosition: groupPosition
            )

            result.append(.message(displayModel))
        }

        return result
    }

    private static func shouldInsertDateSeparator(current: Date, previous: Date?) -> Bool {
        guard let previous = previous else {
            return true
        }

        let calendar = Calendar.current
        return !calendar.isDate(current, inSameDayAs: previous)
    }

    private static func formatDateSeparator(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "오늘"
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            return DateFormatter.dateSeparator.string(from: date)
        }
    }

    private static func determineGroupPosition(
        current: ChatEntity,
        currentDate: Date,
        previous: ChatEntity?,
        previousDate: Date?,
        next: ChatEntity?,
        nextDate: Date?
    ) -> MessageGroupPosition {
        let isFirstInGroup = isFirstMessage(
            current: current,
            currentDate: currentDate,
            previous: previous,
            previousDate: previousDate
        )

        let isLastInGroup = isLastMessage(
            current: current,
            currentDate: currentDate,
            next: next,
            nextDate: nextDate
        )

        switch (isFirstInGroup, isLastInGroup) {
        case (true, true):
            return .single
        case (true, false):
            return .first
        case (false, true):
            return .last
        case (false, false):
            return .middle
        }
    }

    private static func isFirstMessage(
        current: ChatEntity,
        currentDate: Date,
        previous: ChatEntity?,
        previousDate: Date?
    ) -> Bool {
        guard let previous = previous, let previousDate = previousDate else {
            return true
        }

        if current.sender.userId != previous.sender.userId {
            return true
        }

        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: previousDate) {
            return true
        }

        let timeDifference = currentDate.timeIntervalSince(previousDate)
        if timeDifference >= 60 {
            return true
        }

        return false
    }

    private static func isLastMessage(
        current: ChatEntity,
        currentDate: Date,
        next: ChatEntity?,
        nextDate: Date?
    ) -> Bool {
        guard let next = next, let nextDate = nextDate else {
            return true
        }

        if current.sender.userId != next.sender.userId {
            return true
        }

        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: nextDate) {
            return true
        }

        let timeDifference = nextDate.timeIntervalSince(currentDate)
        if timeDifference >= 60 {
            return true
        }

        return false
    }
}
