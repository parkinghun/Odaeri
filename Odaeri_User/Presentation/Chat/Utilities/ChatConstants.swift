//
//  ChatConstants.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/23/26.
//

import Foundation
import CoreGraphics

enum ChatConstants {
    enum Layout {
        static let profileSize: CGFloat = 32
        static let maxBubbleWidthRatio: CGFloat = 0.7
        static let singleImageMaxSize: CGFloat = 240
        static let gridSize: CGFloat = 240
        static let fileHeight: CGFloat = 60
        static let bubbleCornerRadius: CGFloat = 8
    }

    enum Pagination {
        static let initialLimit = 30
        static let pageSize = 30
        static let threshold: CGFloat = 800
        static let bottomThreshold: CGFloat = 100
    }

    enum Timing {
        static let gapDetectionThreshold: TimeInterval = 300
        static let messageGroupingInterval: TimeInterval = 60
    }
}
