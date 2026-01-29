//
//  ChatSenderRole+Presentation.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import UIKit

extension ChatSenderRole {
    enum Alignment {
        case leading
        case trailing
    }

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

    var textAlignment: NSTextAlignment {
        return .left
    }

    var contentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}
