//
//  AttendanceEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation

struct AttendanceEntity {
    let lastCheckInDate: Date?
    let isCheckedInToday: Bool

    init(lastCheckInDate: Date?) {
        self.lastCheckInDate = lastCheckInDate
        self.isCheckedInToday = Self.isToday(lastCheckInDate)
    }

    private static func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}
