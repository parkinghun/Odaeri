//
//  ChatItem.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

enum ChatItem: Hashable {
    case message(ChatDisplayModel)
    case dateSeparator(String)

    var id: String {
        switch self {
        case .message(let model):
            return model.id
        case .dateSeparator(let dateText):
            return "separator_\(dateText)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatItem, rhs: ChatItem) -> Bool {
        return lhs.id == rhs.id
    }
}
