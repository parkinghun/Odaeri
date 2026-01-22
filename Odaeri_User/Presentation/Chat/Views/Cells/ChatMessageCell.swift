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
    private let actionStackView = UIStackView()
    private let retryButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let statusHintLabel = UILabel()

    private var textView: UITextView?
    private var imageGridView: ChatImageGridView?
    private var videoView: ChatVideoView?
    private var fileView: ChatFileView?

    private var currentLayoutData: ChatMessageCellLayoutData?
    private var currentProfileImageUrl: String?

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let bubbleCornerRadius: CGFloat = 8
        static let actionSpacing: CGFloat = 8
        static let actionButtonHeight: CGFloat = 24
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

        actionStackView.axis = .horizontal
        actionStackView.alignment = .center
        actionStackView.spacing = Layout.actionSpacing

        statusHintLabel.font = AppFont.caption2
        statusHintLabel.textColor = AppColor.errorRed
        statusHintLabel.text = "업로드에 실패했습니다"
        statusHintLabel.isHidden = true

        retryButton.setTitle("재전송", for: .normal)
        retryButton.titleLabel?.font = AppFont.caption1
        retryButton.setTitleColor(AppColor.errorRed, for: .normal)

        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.titleLabel?.font = AppFont.caption1
        deleteButton.setTitleColor(AppColor.gray75, for: .normal)

        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(statusStackView)
        contentView.addSubview(statusHintLabel)
        contentView.addSubview(actionStackView)

        statusStackView.addArrangedSubview(activityIndicator)
        statusStackView.addArrangedSubview(errorIconImageView)

        actionStackView.addArrangedSubview(retryButton)
        actionStackView.addArrangedSubview(deleteButton)

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)

        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        profileImageView.addGestureRecognizer(profileTapGesture)
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
            textView?.frame = textFrame
        }

        if let imageGridFrame = layoutData.imageGridFrame {
            imageGridView?.frame = imageGridFrame
        }

        if let videoFrame = layoutData.videoFrame {
            videoView?.frame = videoFrame
        }

        if let fileFrame = layoutData.fileFrame {
            fileView?.frame = fileFrame
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        timeLabel.text = nil
        currentLayoutData = nil
        currentProfileImageUrl = nil

        textView?.isHidden = true
        imageGridView?.isHidden = true
        videoView?.isHidden = true
        fileView?.isHidden = true
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

        for content in layoutData.contents {
            switch content {
            case .text(let text):
                if textView == nil {
                    let tv = createTextView(senderType: layoutData.senderType)
                    bubbleView.addSubview(tv)
                    textView = tv
                }
                textView?.text = text
                textView?.textColor = layoutData.senderType.textColor
                textView?.textAlignment = layoutData.senderType.textAlignment
                textView?.isHidden = false
                hasText = true

            case .imageGroup(let urls):
                if imageGridView == nil {
                    let grid = ChatImageGridView()
                    grid.translatesAutoresizingMaskIntoConstraints = true
                    contentView.addSubview(grid)
                    imageGridView = grid
                }
                imageGridView?.configure(with: urls, status: layoutData.status, progress: layoutData.uploadProgress)
                imageGridView?.onImageTapped = { [weak self] index in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapImageAt: index, in: urls)
                }
                imageGridView?.onRetryTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: layoutData.messageId)
                }
                imageGridView?.isHidden = false
                hasImageGrid = true

            case .video(let thumbnailUrl, let videoUrl):
                if videoView == nil {
                    let video = ChatVideoView()
                    video.translatesAutoresizingMaskIntoConstraints = true
                    contentView.addSubview(video)
                    videoView = video
                }
                videoView?.configure(
                    thumbnailUrl: thumbnailUrl,
                    videoUrl: videoUrl,
                    status: layoutData.status,
                    progress: layoutData.uploadProgress
                )
                videoView?.onVideoTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapVideo: videoUrl)
                }
                videoView?.onRetryTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: layoutData.messageId)
                }
                videoView?.isHidden = false
                hasVideo = true

            case .file(let fileInfo):
                if fileView == nil {
                    let file = ChatFileView()
                    file.translatesAutoresizingMaskIntoConstraints = true
                    contentView.addSubview(file)
                    fileView = file
                }
                fileView?.configure(with: fileInfo)
                fileView?.onFileTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapFile: fileInfo)
                }
                fileView?.isHidden = false
                hasFile = true
            }
        }

        bubbleView.isHidden = !hasText

        if !hasImageGrid {
            imageGridView?.isHidden = true
        }
        if !hasVideo {
            videoView?.isHidden = true
        }
        if !hasFile {
            fileView?.isHidden = true
        }

        applyStyle(for: layoutData.senderType)
        configureStatusUI(status: layoutData.status, senderType: layoutData.senderType)
    }

    private func createTextView(senderType: SenderType) -> UITextView {
        let textView = UITextView()

        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = [.link, .phoneNumber]

        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping

        textView.font = AppFont.body2
        textView.textColor = senderType.textColor
        textView.tintColor = AppColor.blackSprout.withAlphaComponent(0.3)
        textView.linkTextAttributes = [
            .foregroundColor: AppColor.blackSprout,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        textView.textAlignment = senderType.textAlignment

        return textView
    }

    private func applyStyle(for senderType: SenderType) {
        bubbleView.backgroundColor = senderType.bubbleBackgroundColor
    }

    private func configureStatusUI(status: ChatMessageStatus, senderType: SenderType) {
        let isMine = senderType == .me
        actionStackView.isHidden = !isMine
        errorIconImageView.isHidden = true
        activityIndicator.stopAnimating()
        statusHintLabel.isHidden = true

        timeLabel.alpha = 1
        timeLabel.textColor = AppColor.gray60

        guard isMine else {
            actionStackView.isHidden = true
            return
        }

        switch status {
        case .sending:
            activityIndicator.startAnimating()
            timeLabel.alpha = 0.5
            actionStackView.isHidden = true
            statusHintLabel.isHidden = true
        case .failed:
            errorIconImageView.isHidden = false
            timeLabel.textColor = AppColor.errorRed
            actionStackView.isHidden = false
            statusHintLabel.isHidden = false
        case .sent:
            actionStackView.isHidden = true
            statusHintLabel.isHidden = true
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

    @objc private func handleProfileTap() {
        guard let userId = currentLayoutData?.senderUserId, !userId.isEmpty else { return }
        delegate?.chatMessageCell(self, didTapProfile: userId)
    }
}
