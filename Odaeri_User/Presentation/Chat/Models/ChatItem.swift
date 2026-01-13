//
//  ChatItem.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

enum ChatItem: Hashable {
    case message(ChatDisplayModel)
    case dateSeparator(DateSeparator)

    struct DateSeparator: Hashable {
        let id: String
        let text: String
    }

    var id: String {
        switch self {
        case .message(let model):
            return model.id
        case .dateSeparator(let separator):
            return separator.id
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .message(let model):
            hasher.combine(model)
        case .dateSeparator(let separator):
            hasher.combine(separator)
        }
    }

    static func == (lhs: ChatItem, rhs: ChatItem) -> Bool {
        switch (lhs, rhs) {
        case (.message(let left), .message(let right)):
            return left == right
        case (.dateSeparator(let left), .dateSeparator(let right)):
            return left == right
        default:
            return false
        }
    }
}
