//
//  ChatMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct ChatMapper {
    private static let dateCache = NSCache<NSString, NSDate>()
    private static let timeTextCache = NSCache<NSDate, NSString>()

    static func getCachedDate(from isoString: String) -> Date {
        let key = isoString as NSString

        if let cached = dateCache.object(forKey: key) {
            return cached as Date
        }

        let date = DateFormatter.iso8601.date(from: isoString) ?? .distantPast
        dateCache.setObject(date as NSDate, forKey: key)
        return date
    }

    private static func getCachedTimeText(from date: Date) -> String {
        let key = date as NSDate

        if let cached = timeTextCache.object(forKey: key) {
            return cached as String
        }

        let timeText = DateFormatter.timeDisplay.string(from: date)
        timeTextCache.setObject(timeText as NSString, forKey: key)
        return timeText
    }

    static func map(_ entities: [ChatEntity], currentUserId: String) -> [ChatItem] {
        guard !entities.isEmpty else { return [] }

        let sorted = sortForDisplay(entities)
        let dates = sorted.map { getCachedDate(from: $0.createdAt) }

        var result: [ChatItem] = []

        for (index, entity) in sorted.enumerated() {
            let createdAt = dates[index]
            let previousDate = index > 0 ? dates[index - 1] : nil
            let nextDate = index < dates.count - 1 ? dates[index + 1] : nil

            let previous = index > 0 ? sorted[index - 1] : nil
            let next = index < sorted.count - 1 ? sorted[index + 1] : nil

            let senderType: ChatSenderRole = entity.sender.userId == currentUserId ? .me : .other

            let groupPosition = determineGroupPosition(
                current: entity,
                currentDate: createdAt,
                previous: previous,
                previousDate: previousDate,
                next: next,
                nextDate: nextDate
            )

            let contents = ChatMessageContent.parse(
                chatId: entity.chatId,
                content: entity.content,
                files: entity.files
            )

            if shouldInsertDateSeparator(current: createdAt, previous: previousDate) {
                let dateText = formatDateSeparator(createdAt)
                let separatorId = "separator_\(createdAt.timeIntervalSince1970)"
                let separator = ChatItem.DateSeparator(id: separatorId, text: dateText)
                result.append(.dateSeparator(separator))
            }

            let displayModel = ChatDisplayModel(
                id: entity.chatId,
                content: entity.content,
                createdAt: createdAt,
                timeText: getCachedTimeText(from: createdAt),
                senderName: entity.sender.nick,
                senderUserId: entity.sender.userId,
                senderProfileImageUrl: entity.sender.profileImage,
                hasFiles: entity.hasFiles,
                files: entity.files,
                contents: contents,
                status: entity.status,
                uploadProgress: entity.uploadProgress,
                senderType: senderType,
                groupPosition: groupPosition
            )

            result.append(.message(displayModel))
        }

        return result
    }

    private static func sortForDisplay(_ entities: [ChatEntity]) -> [ChatEntity] {
        return entities.sorted { lhs, rhs in
            let leftFailed = lhs.status == .failed
            let rightFailed = rhs.status == .failed

            if leftFailed != rightFailed {
                return !leftFailed
            }

            let leftDate = getCachedDate(from: lhs.createdAt)
            let rightDate = getCachedDate(from: rhs.createdAt)
            return leftDate < rightDate
        }
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

        let timeDifference = abs(currentDate.timeIntervalSince(previousDate))
        if timeDifference >= ChatTimingConstants.messageGroupingInterval {
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

        let timeDifference = abs(currentDate.timeIntervalSince(nextDate))
        if timeDifference >= ChatTimingConstants.messageGroupingInterval {
            return true
        }

        return false
    }
}
