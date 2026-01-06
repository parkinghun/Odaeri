//
//  Date+Extension.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

extension Date {
    /// "2025년 4월 21일 오후 7:21" 형식
    var toFullDisplay: String {
        return DateFormatter.fullDisplay.string(from: self)
    }
    
    /// "오후 6:24" 형식
    var toTimeDisplay: String {
        return DateFormatter.timeDisplay.string(from: self)
    }
    
    /// "n분 전 / n시간 전" (Relative Time)
    var toRelativeTime: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return day >= 7 ? self.toFullDisplay : "\(day)일 전"
        }
        
        if let hour = components.hour, hour > 0 {
            if let minute = components.minute, minute > 0 {
                return "\(hour)시간 \(minute)분 전"
            }
            return "\(hour)시간 전"
        }
        
        if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        }
        
        return "방금 전"
    }
}
