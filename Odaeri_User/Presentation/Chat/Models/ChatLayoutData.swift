//
//  ChatLayoutData.swift
//  Odaeri
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit

enum ChatCellLayoutData: Equatable {
    case message(ChatMessageCellLayoutData)
    case dateSeparator(ChatDateSeparatorCellLayoutData)
    case `default`
}

struct ChatMessageCellLayoutData: Equatable {
    let contentSize: CGSize

    let profileFrame: CGRect
    let nameFrame: CGRect?
    let bubbleFrame: CGRect
    let timeFrame: CGRect
    let statusFrame: CGRect

    let textFrame: CGRect?
    let imageGridFrame: CGRect?
    let videoFrame: CGRect?
    let fileFrame: CGRect?

    let showProfile: Bool
    let showName: Bool
    let showTime: Bool

    let messageId: String
    let senderName: String
    let senderUserId: String
    let senderProfileImageUrl: String?
    let timeText: String
    let contents: [ChatMessageContent]
    let status: ChatMessageStatus
    let uploadProgress: Float?
    let senderType: SenderType

    func shouldUpdateLayout(_ prevLayout: ChatMessageCellLayoutData?) -> Bool {
        guard let prevLayout = prevLayout else { return true }
        return self.contentSize != prevLayout.contentSize ||
               self.showProfile != prevLayout.showProfile ||
               self.showName != prevLayout.showName ||
               self.bubbleFrame != prevLayout.bubbleFrame
    }
}

struct ChatDateSeparatorCellLayoutData: Equatable {
    let contentSize: CGSize
    let labelFrame: CGRect
    let text: String
}
