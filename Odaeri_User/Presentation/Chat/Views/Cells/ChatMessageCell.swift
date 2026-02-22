//
//  ChatMessageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import Combine

protocol ChatMessageCellDelegate: AnyObject {
    func chatMessageCell(_ cell: ChatMessageCell, didTapImageAt index: Int, in urls: [String])
    func chatMessageCell(_ cell: ChatMessageCell, didTapVideo url: String)
    func chatMessageCell(_ cell: ChatMessageCell, didTapFile fileInfo: ChatMessageContent.FileInfo)
    func chatMessageCell(_ cell: ChatMessageCell, didTapShareCard payload: ShareCardPayload)
    func chatMessageCell(_ cell: ChatMessageCell, didTapProfile userId: String)
    func chatMessageCellDidTapRetry(_ cell: ChatMessageCell, messageId: String)
    func chatMessageCellDidTapDelete(_ cell: ChatMessageCell, messageId: String)
}

final class ChatMessageCell: BaseCollectionViewCell {
    static let reuseIdentifier = String(describing: ChatMessageCell.self)

    weak var delegate: ChatMessageCellDelegate?

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bubbleView = UIView()
    private let timeLabel = UILabel()
    private let statusStackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorIconImageView = UIImageView()
    private let failedActionContainerView = UIView()
    private let failedActionDividerView = UIView()
    private let retryButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    private let textView = UITextView()
    private let imageGridView = ChatImageGridView()
    private let videoView = ChatVideoView()
    private let fileView = ChatFileView()
    private let shareCardView = ChatShareCardView()

    private var currentLayoutData: ChatMessageCellLayoutData?
    private var currentProfileImageUrl: String?
    private var currentSharePayload: ShareCardPayload?

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let bubbleCornerRadius: CGFloat = 8
        static let failedActionButtonWidth: CGFloat = 26
        static let failedActionHeight: CGFloat = 26
        static let failedActionDividerWidth: CGFloat = 1
        static let failedActionSpacing: CGFloat = 6
        static let failedActionMinX: CGFloat = 8
        static let failedActionCornerRadius: CGFloat = 10
        static let failedActionBorderWidth: CGFloat = 1
        static let failedActionRetryIconInset: CGFloat = 7
        static let failedActionDeleteIconInset: CGFloat = 5
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()

        contentView.backgroundColor = AppColor.gray0

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = Layout.profileSize / 2
        profileImageView.backgroundColor = AppColor.gray15

        nameLabel.font = AppFont.caption
        nameLabel.textColor = AppColor.gray75

        bubbleView.layer.cornerCurve = .continuous
        bubbleView.clipsToBounds = true
        bubbleView.layer.cornerRadius = Layout.bubbleCornerRadius

        timeLabel.font = AppFont.caption2
        timeLabel.textColor = AppColor.gray60

        statusStackView.axis = .horizontal
        statusStackView.alignment = .bottom
        statusStackView.spacing = 4

        activityIndicator.hidesWhenStopped = true

        errorIconImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
        errorIconImageView.tintColor = AppColor.errorRed
        errorIconImageView.isHidden = true

        failedActionContainerView.backgroundColor = AppColor.gray15
        failedActionContainerView.layer.cornerCurve = .continuous
        failedActionContainerView.layer.cornerRadius = Layout.failedActionCornerRadius
        failedActionContainerView.layer.borderColor = AppColor.gray30.cgColor
        failedActionContainerView.layer.borderWidth = Layout.failedActionBorderWidth
        failedActionContainerView.clipsToBounds = true
        failedActionContainerView.isHidden = true

        failedActionDividerView.backgroundColor = AppColor.gray30

        retryButton.setImage(AppImage.restart, for: .normal)
        retryButton.tintColor = AppColor.gray75
        retryButton.contentEdgeInsets = UIEdgeInsets(
            top: Layout.failedActionRetryIconInset,
            left: Layout.failedActionRetryIconInset,
            bottom: Layout.failedActionRetryIconInset,
            right: Layout.failedActionRetryIconInset
        )
        retryButton.imageView?.contentMode = .scaleAspectFit

        deleteButton.setImage(AppImage.delete, for: .normal)
        deleteButton.tintColor = AppColor.errorRed
        deleteButton.contentEdgeInsets = UIEdgeInsets(
            top: Layout.failedActionDeleteIconInset,
            left: Layout.failedActionDeleteIconInset,
            bottom: Layout.failedActionDeleteIconInset,
            right: Layout.failedActionDeleteIconInset
        )
        deleteButton.imageView?.contentMode = .scaleAspectFit

        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(statusStackView)
        contentView.addSubview(failedActionContainerView)

        statusStackView.addArrangedSubview(activityIndicator)
        statusStackView.addArrangedSubview(errorIconImageView)

        failedActionContainerView.addSubview(retryButton)
        failedActionContainerView.addSubview(failedActionDividerView)
        failedActionContainerView.addSubview(deleteButton)

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)

        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        profileImageView.addGestureRecognizer(profileTapGesture)

        setupContentViews()
    }

    private func setupContentViews() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = AppFont.body2
        textView.tintColor = AppColor.blackSprout.withAlphaComponent(0.3)
        textView.linkTextAttributes = [
            .foregroundColor: AppColor.blackSprout,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.isHidden = true
        bubbleView.addSubview(textView)

        imageGridView.translatesAutoresizingMaskIntoConstraints = true
        imageGridView.isHidden = true
        contentView.addSubview(imageGridView)

        videoView.translatesAutoresizingMaskIntoConstraints = true
        videoView.isHidden = true
        contentView.addSubview(videoView)

        fileView.translatesAutoresizingMaskIntoConstraints = true
        fileView.isHidden = true
        contentView.addSubview(fileView)

        shareCardView.translatesAutoresizingMaskIntoConstraints = true
        shareCardView.isHidden = true
        shareCardView.isUserInteractionEnabled = true
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(handleShareCardTap))
        shareCardView.addGestureRecognizer(shareTap)
        contentView.addSubview(shareCardView)
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attrs = layoutAttributes as? ChatCollectionViewLayoutAttributes,
              case .message(let layoutData) = attrs.cellLayoutData else {
            return
        }

        currentLayoutData = layoutData
        configure(with: layoutData)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let layoutData = currentLayoutData else { return }

        profileImageView.frame = layoutData.profileFrame
        timeLabel.frame = layoutData.timeFrame
        statusStackView.frame = layoutData.statusFrame

        if let nameFrame = layoutData.nameFrame {
            nameLabel.frame = nameFrame
        }

        bubbleView.frame = layoutData.bubbleFrame

        if let textFrame = layoutData.textFrame {
            textView.frame = textFrame
        }

        if let imageGridFrame = layoutData.imageGridFrame {
            imageGridView.frame = imageGridFrame
        }

        if let videoFrame = layoutData.videoFrame {
            videoView.frame = videoFrame
        }

        if let fileFrame = layoutData.fileFrame {
            fileView.frame = fileFrame
        }

        if let shareCardFrame = layoutData.shareCardFrame {
            shareCardView.frame = shareCardFrame
        }

        layoutFailedActionButtons()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        timeLabel.text = nil
        currentLayoutData = nil
        currentProfileImageUrl = nil
        currentSharePayload = nil

        textView.isHidden = true
        imageGridView.isHidden = true
        videoView.isHidden = true
        fileView.isHidden = true
        shareCardView.isHidden = true
        failedActionContainerView.isHidden = true
    }

    private func configure(with layoutData: ChatMessageCellLayoutData) {
        nameLabel.text = layoutData.senderName
        timeLabel.text = layoutData.timeText

        nameLabel.isHidden = !layoutData.showName
        timeLabel.isHidden = !layoutData.showTime
        profileImageView.isUserInteractionEnabled = layoutData.senderType == .other && layoutData.showProfile

        let imageUrl = layoutData.senderProfileImageUrl

        if layoutData.showProfile {
            if currentProfileImageUrl != imageUrl || profileImageView.image == nil {
                currentProfileImageUrl = imageUrl
                if let urlString = imageUrl {
                    profileImageView.setImage(url: urlString, placeholder: AppImage.person, animated: false)
                } else {
                    profileImageView.image = AppImage.person
                }
            }
            profileImageView.isHidden = false
        } else {
            profileImageView.isHidden = true
        }

        var hasText = false
        var hasImageGrid = false
        var hasVideo = false
        var hasFile = false
        var hasShareCard = false

        for content in layoutData.contents {
            switch content {
            case .text(let text):
                textView.text = text
                textView.textColor = layoutData.senderType.textColor
                textView.textAlignment = layoutData.senderType.textAlignment
                textView.isHidden = false
                hasText = true

            case .imageGroup(let urls):
                imageGridView.configure(with: urls, status: layoutData.status, progress: layoutData.uploadProgress)
                imageGridView.onImageTapped = { [weak self] index in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapImageAt: index, in: urls)
                }
                imageGridView.onRetryTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: layoutData.messageId)
                }
                imageGridView.isHidden = false
                hasImageGrid = true

            case .video(let thumbnailUrl, let videoUrl):
                videoView.configure(
                    thumbnailUrl: thumbnailUrl,
                    videoUrl: videoUrl,
                    status: layoutData.status,
                    progress: layoutData.uploadProgress
                )
                videoView.onVideoTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapVideo: videoUrl)
                }
                videoView.onRetryTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: layoutData.messageId)
                }
                videoView.isHidden = false
                hasVideo = true

            case .file(let fileInfo):
                fileView.configure(with: fileInfo)
                fileView.onFileTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapFile: fileInfo)
                }
                fileView.isHidden = false
                hasFile = true

            case .shareCard(let payload):
                currentSharePayload = payload
                shareCardView.configure(payload: payload)
                shareCardView.isHidden = false
                hasShareCard = true
            }
        }

        bubbleView.isHidden = !hasText

        if !hasImageGrid {
            imageGridView.isHidden = true
        }
        if !hasVideo {
            videoView.isHidden = true
        }
        if !hasFile {
            fileView.isHidden = true
        }
        if !hasShareCard {
            shareCardView.isHidden = true
        }

        applyStyle(for: layoutData.senderType)
        configureStatusUI(status: layoutData.status, senderType: layoutData.senderType)
    }

    func applyLayoutData(_ layoutData: ChatMessageCellLayoutData) {
        currentLayoutData = layoutData
        configure(with: layoutData)
        setNeedsLayout()
    }

    private func applyStyle(for senderType: ChatSenderRole) {
        bubbleView.backgroundColor = senderType.bubbleBackgroundColor
    }

    private func layoutFailedActionButtons() {
        let actionWidth = Layout.failedActionButtonWidth * 2 + Layout.failedActionDividerWidth
        let actionHeight = Layout.failedActionHeight

        let messageFrame = messageContentFrame()
        guard !messageFrame.isNull else {
            failedActionContainerView.frame = .zero
            return
        }

        let actionX = max(
            Layout.failedActionMinX,
            messageFrame.minX - Layout.failedActionSpacing - actionWidth
        )
        let actionY = max(0, messageFrame.maxY - actionHeight)

        failedActionContainerView.frame = CGRect(
            x: actionX,
            y: actionY,
            width: actionWidth,
            height: actionHeight
        )

        retryButton.frame = CGRect(
            x: 0,
            y: 0,
            width: Layout.failedActionButtonWidth,
            height: actionHeight
        )
        failedActionDividerView.frame = CGRect(
            x: Layout.failedActionButtonWidth,
            y: 0,
            width: Layout.failedActionDividerWidth,
            height: actionHeight
        )
        deleteButton.frame = CGRect(
            x: Layout.failedActionButtonWidth + Layout.failedActionDividerWidth,
            y: 0,
            width: Layout.failedActionButtonWidth,
            height: actionHeight
        )
    }

    private func messageContentFrame() -> CGRect {
        var result = CGRect.null
        let frames = [
            bubbleView.frame,
            imageGridView.frame,
            videoView.frame,
            fileView.frame,
            shareCardView.frame
        ]

        for frame in frames where !frame.isEmpty {
            result = result.isNull ? frame : result.union(frame)
        }

        return result
    }

    private func configureStatusUI(status: ChatMessageStatus, senderType: ChatSenderRole) {
        let isMine = senderType == .me
        failedActionContainerView.isHidden = true
        errorIconImageView.isHidden = true
        activityIndicator.stopAnimating()

        guard isMine else {
            return
        }

        switch status {
        case .sending:
            activityIndicator.startAnimating()
            failedActionContainerView.isHidden = true
            timeLabel.isHidden = false
            timeLabel.alpha = 0.5
            timeLabel.textColor = AppColor.gray60
        case .failed:
            failedActionContainerView.isHidden = false
            errorIconImageView.isHidden = true
            timeLabel.isHidden = true
        case .sent:
            failedActionContainerView.isHidden = true
            timeLabel.isHidden = false
            timeLabel.alpha = 1
            timeLabel.textColor = AppColor.gray60
        }
    }

    @objc private func handleRetryTap() {
        guard let messageId = currentLayoutData?.messageId else { return }
        delegate?.chatMessageCellDidTapRetry(self, messageId: messageId)
    }

    @objc private func handleDeleteTap() {
        guard let messageId = currentLayoutData?.messageId else { return }
        delegate?.chatMessageCellDidTapDelete(self, messageId: messageId)
    }

    @objc private func handleShareCardTap() {
        guard let payload = currentSharePayload else { return }
        delegate?.chatMessageCell(self, didTapShareCard: payload)
    }

    @objc private func handleProfileTap() {
        guard let userId = currentLayoutData?.senderUserId, !userId.isEmpty else { return }
        delegate?.chatMessageCell(self, didTapProfile: userId)
    }
}
