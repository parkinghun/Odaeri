//
//  SenderType.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit

enum SenderType {
    case me
    case other

    var alignment: Alignment {
        switch self {
        case .me:
            return .trailing
        case .other:
            return .leading
        }
    }

    var bubbleBackgroundColor: UIColor {
        switch self {
        case .me:
            return AppColor.blackSprout
        case .other:
            return AppColor.gray15
        }
    }

    var textColor: UIColor {
        switch self {
        case .me:
            return AppColor.gray0
        case .other:
            return AppColor.gray90
        }
    }

    var needsProfileLayout: Bool {
        switch self {
        case .me:
            return false
        case .other:
            return true
        }
    }

    var textAlignment: NSTextAlignment {
        switch self {
        case .me:
            return .right
        case .other:
            return .left
        }
    }

    var contentInsets: UIEdgeInsets {
        switch self {
        case .me:
            return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        case .other:
            return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
    }

    enum Alignment {
        case leading
        case trailing
    }
}
