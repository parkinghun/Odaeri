//
//  AttendanceService.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation

protocol AttendanceServiceProtocol {
    func getAttendanceStatus() -> AttendanceEntity
    func checkIn() -> Bool
    func resetForTesting()
}

final class AttendanceService: AttendanceServiceProtocol {
    static let shared = AttendanceService()

    private let userDefaults: UserDefaults
    private let lastCheckInKey = "com.odaeri.lastCheckInDate"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getAttendanceStatus() -> AttendanceEntity {
        let lastDate = userDefaults.object(forKey: lastCheckInKey) as? Date
        return AttendanceEntity(lastCheckInDate: lastDate)
    }

    @discardableResult
    func checkIn() -> Bool {
        let status = getAttendanceStatus()

        guard !status.isCheckedInToday else {
            return false
        }

        userDefaults.set(Date(), forKey: lastCheckInKey)
        return true
    }

    func resetForTesting() {
        userDefaults.removeObject(forKey: lastCheckInKey)
    }
}
