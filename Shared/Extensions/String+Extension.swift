//
//  String+Extension.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

extension String {
    /// ISO8601 형식의 String 을 Date? 으로 리턴
    func toDate() -> Date? {
        let formatter = DateFormatter()
        // 서버의 표준 ISO8601 형식에 밀리초(.SSS) 추가
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter.date(from: self)
    }
}
