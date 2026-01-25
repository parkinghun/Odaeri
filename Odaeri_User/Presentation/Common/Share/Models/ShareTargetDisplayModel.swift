//
//  ShareTargetDisplayModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation

struct ShareTargetDisplayModel: Hashable {
    let userId: String
    let nick: String
    let profileImage: String?
    let isSelected: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(isSelected)
    }

    static func == (lhs: ShareTargetDisplayModel, rhs: ShareTargetDisplayModel) -> Bool {
        return lhs.userId == rhs.userId && lhs.isSelected == rhs.isSelected
    }
}
