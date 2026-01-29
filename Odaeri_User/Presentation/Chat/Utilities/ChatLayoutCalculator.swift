//
//  ChatLayoutCalculator.swift
//  Odaeri
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit

struct ChatLayoutCalculator {
    private enum Layout {
        static let profileSize: CGFloat = ChatConstants.Layout.profileSize
        static let horizontalSpacing: CGFloat = AppSpacing.small
        static let verticalSpacing: CGFloat = AppSpacing.xSmall
        static let contentInset: CGFloat = AppSpacing.large
        static let bubbleCornerRadius: CGFloat = ChatConstants.Layout.bubbleCornerRadius
        static let textPadding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let nameHeight: CGFloat = 16
        static let timeSpacing: CGFloat = 2
        static let singleImageMaxSize: CGFloat = ChatConstants.Layout.singleImageMaxSize
        static let gridMaxWidth: CGFloat = ChatConstants.Layout.gridSize
        static let imageGridSpacing: CGFloat = ChatConstants.Layout.imageGridSpacing
        static let contentSpacing: CGFloat = 4
        static let fileHeight: CGFloat = ChatConstants.Layout.fileHeight
        static let maxBubbleWidthRatio: CGFloat = ChatConstants.Layout.maxBubbleWidthRatio
        static let shareCardImageHeight: CGFloat = 120
        static let shareCardHorizontalPadding: CGFloat = 12
        static let shareCardVerticalPadding: CGFloat = 10
        static let shareCardTagHeight: CGFloat = 14
        static let shareCardTitleSpacing: CGFloat = 6
    }

    static func calculateMessageLayout(
        displayModel: ChatDisplayModel,
        containerWidth: CGFloat
    ) -> ChatMessageCellLayoutData {
        let senderType = displayModel.senderType
        let isMe = senderType == .me
        let showProfile = displayModel.showProfile
        let showName = displayModel.showName
        let showTime = displayModel.showTime

        var currentY: CGFloat = AppSpacing.small

        let profileSpace = senderType == .other ? Layout.profileSize : 0
        let profileSpacing = senderType == .other ? Layout.horizontalSpacing : 0

        let timeWidth = calculateTimeWidth(text: displayModel.timeText)

        let maxBubbleWidth = containerWidth * Layout.maxBubbleWidthRatio
        let maxContentWidth = min(
            maxBubbleWidth,
            containerWidth - Layout.contentInset * 2 - profileSpace - profileSpacing
        )

        var profileFrame = CGRect.zero
        var nameFrame: CGRect?
        var textFrame: CGRect?
        var imageGridFrame: CGRect?
        var videoFrame: CGRect?
        var fileFrame: CGRect?
        var shareCardFrame: CGRect?
        var bubbleFrame = CGRect.zero
        var timeFrame = CGRect.zero
        var statusFrame = CGRect.zero

        var contentX: CGFloat = Layout.contentInset

        if !isMe {
            profileFrame = CGRect(
                x: contentX,
                y: currentY,
                width: showProfile ? Layout.profileSize : 0,
                height: showProfile ? Layout.profileSize : 0
            )
            contentX += profileSpace + profileSpacing
        }

        if showName {
            nameFrame = CGRect(
                x: contentX,
                y: currentY,
                width: maxContentWidth,
                height: Layout.nameHeight
            )
            currentY += Layout.nameHeight + Layout.verticalSpacing
        }

        var bubbleWidth: CGFloat = 0
        var bubbleHeight: CGFloat = 0
        var hasText = false
        var totalMediaHeight: CGFloat = 0
        var mediaCount = 0

        for content in displayModel.contents {
            switch content {
            case .text(let text):
                let maxTextWidth = maxContentWidth - Layout.textPadding.left - Layout.textPadding.right

                let textSize = text.boundingRect(
                    with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: AppFont.body2],
                    context: nil
                ).size

                let textWidth = ceil(textSize.width)
                let textHeight = ceil(textSize.height)

                bubbleWidth = textWidth + Layout.textPadding.left + Layout.textPadding.right
                bubbleHeight = textHeight + Layout.textPadding.top + Layout.textPadding.bottom

                textFrame = CGRect(
                    x: Layout.textPadding.left,
                    y: Layout.textPadding.top,
                    width: textWidth,
                    height: textHeight
                )

                hasText = true

            case .imageGroup(let urls):
                let imageCount = urls.count
                let (gridWidth, gridHeight) = calculateImageGridSize(
                    count: imageCount,
                    maxWidth: maxContentWidth,
                    spacing: Layout.imageGridSpacing
                )

                imageGridFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: gridWidth,
                    height: gridHeight
                )
                totalMediaHeight += gridHeight
                mediaCount += 1

            case .video:
                videoFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: Layout.gridMaxWidth,
                    height: Layout.gridMaxWidth
                )
                totalMediaHeight += Layout.gridMaxWidth
                mediaCount += 1

            case .file:
                fileFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: Layout.gridMaxWidth,
                    height: Layout.fileHeight
                )
                totalMediaHeight += Layout.fileHeight
                mediaCount += 1

            case .shareCard(let payload):
                let cardSize = calculateShareCardSize(
                    title: payload.title,
                    maxWidth: maxContentWidth
                )
                shareCardFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: cardSize.width,
                    height: cardSize.height
                )
                totalMediaHeight += cardSize.height
                mediaCount += 1
            }
        }

        if mediaCount > 1 {
            totalMediaHeight += Layout.contentSpacing * CGFloat(mediaCount - 1)
        }

        let messageContentY = currentY
        var messageBottomY: CGFloat = messageContentY

        if hasText {
            let bubbleX = isMe
                ? containerWidth - Layout.contentInset - bubbleWidth
                : contentX

            bubbleFrame = CGRect(
                x: bubbleX,
                y: messageContentY,
                width: bubbleWidth,
                height: bubbleHeight
            )

            messageBottomY = bubbleFrame.maxY
            currentY = bubbleFrame.maxY

            if totalMediaHeight > 0 {
                currentY += Layout.contentSpacing
            }
        }

        if totalMediaHeight > 0 {
            var mediaY = currentY

            if var cardFrame = shareCardFrame {
                let mediaX = isMe
                    ? containerWidth - Layout.contentInset - cardFrame.width
                    : contentX
                cardFrame.origin = CGPoint(x: mediaX, y: mediaY)
                shareCardFrame = cardFrame
                mediaY += cardFrame.height + Layout.contentSpacing
            }

            if var imageFrame = imageGridFrame {
                let mediaX = isMe
                    ? containerWidth - Layout.contentInset - imageFrame.width
                    : contentX
                imageFrame.origin = CGPoint(x: mediaX, y: mediaY)
                imageGridFrame = imageFrame
                mediaY += imageFrame.height + Layout.contentSpacing
            }

            if var vFrame = videoFrame {
                let mediaX = isMe
                    ? containerWidth - Layout.contentInset - vFrame.width
                    : contentX
                vFrame.origin = CGPoint(x: mediaX, y: mediaY)
                videoFrame = vFrame
                mediaY += vFrame.height + Layout.contentSpacing
            }

            if var fFrame = fileFrame {
                let mediaX = isMe
                    ? containerWidth - Layout.contentInset - fFrame.width
                    : contentX
                fFrame.origin = CGPoint(x: mediaX, y: mediaY)
                fileFrame = fFrame
                mediaY += fFrame.height
            }

            messageBottomY = mediaY
            currentY = messageBottomY
        }

        let timeHeight = calculateTimeHeight()

        let contentMaxX: CGFloat
        let contentMinX: CGFloat

        if let cardFrame = shareCardFrame {
            contentMaxX = cardFrame.maxX
            contentMinX = cardFrame.minX
        } else if let fFrame = fileFrame {
            contentMaxX = fFrame.maxX
            contentMinX = fFrame.minX
        } else if let vFrame = videoFrame {
            contentMaxX = vFrame.maxX
            contentMinX = vFrame.minX
        } else if let imageFrame = imageGridFrame {
            contentMaxX = imageFrame.maxX
            contentMinX = imageFrame.minX
        } else if bubbleFrame.width > 0 {
            contentMaxX = bubbleFrame.maxX
            contentMinX = bubbleFrame.minX
        } else {
            contentMaxX = 0
            contentMinX = 0
        }

        let timeX = isMe
            ? contentMinX - timeWidth - Layout.timeSpacing
            : contentMaxX + Layout.timeSpacing

        timeFrame = CGRect(
            x: timeX,
            y: messageBottomY - timeHeight,
            width: timeWidth,
            height: timeHeight
        )

        statusFrame = timeFrame

        currentY += AppSpacing.small

        let contentSize = CGSize(width: containerWidth, height: currentY)

        return ChatMessageCellLayoutData(
            contentSize: contentSize,
            profileFrame: profileFrame,
            nameFrame: nameFrame,
            bubbleFrame: bubbleFrame,
            timeFrame: timeFrame,
            statusFrame: statusFrame,
            textFrame: textFrame,
            imageGridFrame: imageGridFrame,
            videoFrame: videoFrame,
            fileFrame: fileFrame,
            shareCardFrame: shareCardFrame,
            showProfile: showProfile,
            showName: showName,
            showTime: showTime,
            messageId: displayModel.id,
            senderName: displayModel.senderName,
            senderUserId: displayModel.senderUserId,
            senderProfileImageUrl: displayModel.senderProfileImageUrl,
            timeText: displayModel.timeText,
            contents: displayModel.contents,
            status: displayModel.status,
            uploadProgress: displayModel.uploadProgress,
            senderType: senderType
        )
    }

    private static func calculateShareCardSize(title: String, maxWidth: CGFloat) -> CGSize {
        let cardWidth = maxWidth
        let textMaxWidth = cardWidth - Layout.shareCardHorizontalPadding * 2

        let titleSize = title.boundingRect(
            with: CGSize(width: textMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: AppFont.body2],
            context: nil
        ).size

        let titleHeight = ceil(titleSize.height)

        let textHeight = Layout.shareCardTagHeight +
            Layout.shareCardTitleSpacing +
            titleHeight +
            Layout.shareCardVerticalPadding * 2

        let totalHeight = Layout.shareCardImageHeight + textHeight

        return CGSize(width: cardWidth, height: totalHeight)
    }

    static func calculateDateSeparatorLayout(
        text: String,
        containerWidth: CGFloat
    ) -> ChatDateSeparatorCellLayoutData {
        let textSize = text.boundingRect(
            with: CGSize(width: containerWidth - 40, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: AppFont.caption1],
            context: nil
        ).size

        let labelHeight = ceil(textSize.height)
        let totalHeight = labelHeight + AppSpacing.small * 2

        let labelFrame = CGRect(
            x: (containerWidth - ceil(textSize.width)) / 2,
            y: AppSpacing.small,
            width: ceil(textSize.width),
            height: labelHeight
        )

        return ChatDateSeparatorCellLayoutData(
            contentSize: CGSize(width: containerWidth, height: totalHeight),
            labelFrame: labelFrame,
            text: text
        )
    }

    private static func calculateTimeWidth(text: String) -> CGFloat {
        let size = text.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: AppFont.caption2],
            context: nil
        ).size

        return ceil(size.width)
    }

    private static func calculateTimeHeight() -> CGFloat {
        let size = "00:00".boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: AppFont.caption2],
            context: nil
        ).size

        return ceil(size.height)
    }

    private static func calculateImageGridSize(
        count: Int,
        maxWidth: CGFloat,
        spacing: CGFloat
    ) -> (width: CGFloat, height: CGFloat) {
        let width = min(Layout.gridMaxWidth, maxWidth)

        switch count {
        case 1:
            let size = min(Layout.singleImageMaxSize, width)
            return (size, size)

        case 2:
            let cell = floor((width - spacing) / 2)
            return (width, cell)

        case 3:
            let cell = floor((width - spacing) / 2)
            let height = cell * 2 + spacing
            return (width, height)

        case 4:
            let cell = floor((width - spacing) / 2)
            let height = cell * 2 + spacing
            return (width, height)

        case 5:
            let topCell = floor((width - spacing * 2) / 3)
            let height = topCell + spacing + topCell
            return (width, height)

        default:
            return (width, width)
        }
    }
}
