//
//  ChatSenderRole.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

enum ChatSenderRole: Hashable {
    case me
    case other

    var needsProfileLayout: Bool {
        switch self {
        case .me:
            return false
        case .other:
            return true
        }
    }
}
