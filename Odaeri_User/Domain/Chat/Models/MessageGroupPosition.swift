//
//  MessageGroupPosition.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

enum MessageGroupPosition: Hashable {
    case first
    case middle
    case last
    case single

    var showsProfile: Bool {
        switch self {
        case .first, .single:
            return true
        case .middle, .last:
            return false
        }
    }

    var showsName: Bool {
        switch self {
        case .first, .single:
            return true
        case .middle, .last:
            return false
        }
    }

    var showsTime: Bool {
        switch self {
        case .last, .single:
            return true
        case .first, .middle:
            return false
        }
    }
}
