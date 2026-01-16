//
//  NotificationPayload.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation

enum NotificationPayload {
    static func roomId(from userInfo: [AnyHashable: Any]) -> String? {
        if let roomId = userInfo["roomId"] as? String {
            return roomId
        }
        if let roomId = userInfo["room_id"] as? String {
            return roomId
        }
        if let data = userInfo["data"] as? [String: Any] {
            if let roomId = data["roomId"] as? String {
                return roomId
            }
            if let roomId = data["room_id"] as? String {
                return roomId
            }
        }
        return nil
    }
}
