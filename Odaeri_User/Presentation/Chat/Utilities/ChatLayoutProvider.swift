//
//  ChatLayoutProvider.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation

struct ChatLayoutProvider {
    static func calculateLayout(for item: ChatItem, containerWidth: CGFloat) -> ChatCellLayoutData {
        switch item {
        case .message(let displayModel):
            let layoutData = ChatLayoutCalculator.calculateMessageLayout(
                displayModel: displayModel,
                containerWidth: containerWidth
            )
            return .message(layoutData)

        case .dateSeparator(let separator):
            let layoutData = ChatLayoutCalculator.calculateDateSeparatorLayout(
                text: separator.text,
                containerWidth: containerWidth
            )
            return .dateSeparator(layoutData)
        }
    }
}
