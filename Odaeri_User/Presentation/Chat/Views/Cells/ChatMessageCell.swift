//
//  ChatMessageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import SnapKit

protocol ChatMessageCellDelegate: AnyObject {
    func chatMessageCell(_ cell: ChatMessageCell, didTapImageAt index: Int, in urls: [String])
    func chatMessageCell(_ cell: ChatMessageCell, didTapVideo url: String)
    func chatMessageCell(_ cell: ChatMessageCell, didTapFile fileInfo: ChatMessageContent.FileInfo)
    func chatMessageCell(_ cell: ChatMessageCell, didTapProfile userId: String)
    func chatMessageCellDidTapRetry(_ cell: ChatMessageCell, messageId: String)
    func chatMessageCellDidTapDelete(_ cell: ChatMessageCell, messageId: String)
}

final class ChatMessageCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ChatMessageCell.self)

    weak var delegate: ChatMessageCellDelegate?

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bubbleView = UIView()
    private let bubbleContentStackView = UIStackView()
    private let timeLabel = UILabel()
    private let statusStackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorIconImageView = UIImageView()
    private let actionStackView = UIStackView()
    private let retryButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let statusHintLabel = UILabel()
    private let mediaContentStackView = UIStackView()
    private let messageContentGroup = UIStackView()
    private let horizontalContainerStack = UIStackView()

    private let rootStackView = UIStackView()
    private let contentStackView = UIStackView()

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var currentMessageId: String?
    private var currentStatus: ChatMessageStatus = .sent
    private var currentUploadProgress: Float?
    private var currentHasAttachments: Bool = false
    private var currentHasMedia: Bool = false
    private var shouldReserveProfileSpace = false
    private var currentSenderUserId: String?

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let bubbleCornerRadius: CGFloat = 8
        static let horizontalSpacing: CGFloat = AppSpacing.small
        static let verticalSpacing: CGFloat = AppSpacing.xSmall
        static let contentInset: CGFloat = AppSpacing.large
        static let bubbleContentSpacing: CGFloat = 2
        static let timeSpacingTight: CGFloat = 2
        static let textPadding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let textPaddingTightSide: CGFloat = 2
        static let actionSpacing: CGFloat = 8
        static let actionButtonHeight: CGFloat = 24
        static let maxContentWidth: CGFloat = UIScreen.main.bounds.width * 0.7
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        nameLabel.text = nil
        timeLabel.text = nil
        currentMessageId = nil
        currentStatus = .sent
        currentUploadProgress = nil
        currentHasAttachments = false
        currentHasMedia = false
        shouldReserveProfileSpace = false
        currentSenderUserId = nil

        bubbleContentStackView.arrangedSubviews.forEach {
            bubbleContentStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        mediaContentStackView.arrangedSubviews.forEach {
            mediaContentStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func configure(with model: ChatDisplayModel) {
        print("ChatMessageCell.configure - chatId: \(model.id)")
        print("senderType: \(model.senderType), status: \(model.status), hasFiles: \(model.hasFiles)")

        nameLabel.text = model.senderName
        timeLabel.text = model.timeText
        currentMessageId = model.id
        currentStatus = model.status
        currentUploadProgress = model.uploadProgress
        currentHasAttachments = model.hasFiles

        nameLabel.isHidden = !model.showName
        timeLabel.isHidden = !model.showTime
        shouldReserveProfileSpace = model.senderType == .other
        currentSenderUserId = model.senderUserId
        profileImageView.alpha = model.showProfile ? 1 : 0
        profileImageView.isHidden = false
        profileImageView.isUserInteractionEnabled = model.senderType == .other && model.showProfile

        if model.showProfile {
            if let urlString = model.senderProfileImageUrl {
                profileImageView.setImage(url: urlString, placeholder: AppImage.person)
            } else {
                profileImageView.image = AppImage.person
            }
        } else {
            profileImageView.image = AppImage.person
        }

        var displayContents = model.contents
        let fileContents = ChatMessageContent.parseFiles(files: model.files)
        displayContents.append(contentsOf: fileContents)

        configureContents(
            displayContents,
            senderType: model.senderType,
            status: model.status,
            uploadProgress: model.uploadProgress
        )
        configureStatusUI(status: model.status, senderType: model.senderType)
        applyStyle(for: model.senderType)
        updateLayout(for: model.senderType)
        updateProfileSpacing()

        bubbleView.layer.cornerRadius = Layout.bubbleCornerRadius

        print("bubbleContentStackView.arrangedSubviews.count: \(bubbleContentStackView.arrangedSubviews.count)")
        print("bubbleView.isHidden: \(bubbleView.isHidden)")
    }

    private func configureContents(
        _ contents: [ChatMessageContent],
        senderType: SenderType,
        status: ChatMessageStatus,
        uploadProgress: Float?
    ) {
        var hasText = false
        var hasMedia = false

        for content in contents {
            switch content {
            case .text(let text):
                let textView = createTextView(text: text, senderType: senderType)
                bubbleContentStackView.addArrangedSubview(textView)
                hasText = true

            case .imageGroup(let urls):
                let imageGridView = ChatImageGridView()
                imageGridView.configure(with: urls, status: status, progress: uploadProgress)
                constrainMediaWidth(imageGridView)
                imageGridView.onImageTapped = { [weak self] index in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapImageAt: index, in: urls)
                }
                imageGridView.onRetryTapped = { [weak self] in
                    guard let self = self, let messageId = self.currentMessageId else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: messageId)
                }
                mediaContentStackView.addArrangedSubview(imageGridView)
                hasMedia = true

            case .video(let url):
                let videoView = ChatVideoView()
                videoView.configure(with: url, status: status, progress: uploadProgress)
                constrainMediaWidth(videoView)
                videoView.onVideoTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapVideo: url)
                }
                videoView.onRetryTapped = { [weak self] in
                    guard let self = self, let messageId = self.currentMessageId else { return }
                    self.delegate?.chatMessageCellDidTapRetry(self, messageId: messageId)
                }
                mediaContentStackView.addArrangedSubview(videoView)
                hasMedia = true

            case .file(let fileInfo):
                let fileView = ChatFileView()
                fileView.configure(with: fileInfo)
                constrainMediaWidth(fileView)
                fileView.onFileTapped = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCell(self, didTapFile: fileInfo)
                }
                mediaContentStackView.addArrangedSubview(fileView)
                hasMedia = true
            }
        }

        updateContentLayout(hasText: hasText, hasMedia: hasMedia, senderType: senderType)
    }

    private func createTextView(text: String, senderType: SenderType) -> UITextView {
        let textView = UITextView()

        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = [.link, .phoneNumber]

        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byCharWrapping

        textView.font = AppFont.body2
        textView.textColor = senderType.textColor
        textView.text = text
        textView.tintColor = AppColor.blackSprout.withAlphaComponent(0.3)
        textView.linkTextAttributes = [
            .foregroundColor: AppColor.blackSprout,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        switch senderType.alignment {
        case .leading:
            textView.textAlignment = .left
        case .trailing:
            textView.textAlignment = .right
        }

        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)

        return textView
    }

    private func setupUI() {
        selectionStyle = .none
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

        bubbleContentStackView.axis = .vertical
        bubbleContentStackView.spacing = Layout.bubbleContentSpacing
        bubbleContentStackView.alignment = .leading
        bubbleContentStackView.distribution = .fill

        timeLabel.font = AppFont.caption2
        timeLabel.textColor = AppColor.gray60
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .vertical)
        timeLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        statusStackView.axis = .horizontal
        statusStackView.alignment = .bottom
        statusStackView.spacing = 4
        statusStackView.setContentHuggingPriority(.required, for: .horizontal)
        statusStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusStackView.setContentHuggingPriority(.required, for: .vertical)
        statusStackView.setContentCompressionResistancePriority(.required, for: .vertical)

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

        rootStackView.axis = .horizontal
        rootStackView.alignment = .top
        rootStackView.spacing = Layout.horizontalSpacing

        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = Layout.verticalSpacing

        mediaContentStackView.axis = .vertical
        mediaContentStackView.alignment = .leading
        mediaContentStackView.spacing = Layout.bubbleContentSpacing

        messageContentGroup.axis = .vertical
        messageContentGroup.alignment = .leading
        messageContentGroup.spacing = Layout.bubbleContentSpacing

        horizontalContainerStack.axis = .horizontal
        horizontalContainerStack.alignment = .bottom
        horizontalContainerStack.spacing = Layout.timeSpacingTight

        contentView.addSubview(rootStackView)
        rootStackView.addArrangedSubview(profileImageView)
        rootStackView.addArrangedSubview(contentStackView)

        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(horizontalContainerStack)
        contentStackView.addArrangedSubview(statusHintLabel)
        contentStackView.addArrangedSubview(actionStackView)

        bubbleView.addSubview(bubbleContentStackView)

        statusStackView.addArrangedSubview(timeLabel)
        statusStackView.addArrangedSubview(activityIndicator)
        statusStackView.addArrangedSubview(errorIconImageView)

        messageContentGroup.addArrangedSubview(bubbleView)
        messageContentGroup.addArrangedSubview(mediaContentStackView)

        horizontalContainerStack.addArrangedSubview(statusStackView)
        horizontalContainerStack.addArrangedSubview(messageContentGroup)

        actionStackView.addArrangedSubview(retryButton)
        actionStackView.addArrangedSubview(deleteButton)

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)

        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        profileImageView.addGestureRecognizer(profileTapGesture)
    }

    private func setupConstraints() {
        rootStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(AppSpacing.small)
        }

        leadingConstraint = rootStackView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: Layout.contentInset
        )
        trailingConstraint = rootStackView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -Layout.contentInset
        )

        leadingConstraint?.priority = .required
        trailingConstraint?.priority = .defaultLow
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.profileSize)
        }

        bubbleView.snp.makeConstraints {
            $0.width.lessThanOrEqualToSuperview().multipliedBy(0.75)
        }

        messageContentGroup.snp.makeConstraints {
            $0.width.lessThanOrEqualToSuperview().multipliedBy(0.75)
        }

        bubbleContentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.textPadding)
        }

        retryButton.snp.makeConstraints {
            $0.height.equalTo(Layout.actionButtonHeight)
        }

        deleteButton.snp.makeConstraints {
            $0.height.equalTo(Layout.actionButtonHeight)
        }
    }

    private func applyStyle(for senderType: SenderType) {
        bubbleView.backgroundColor = senderType.bubbleBackgroundColor

        switch senderType.alignment {
        case .leading:
            bubbleContentStackView.alignment = .leading
        case .trailing:
            bubbleContentStackView.alignment = .trailing
        }
    }

    private func updateLayout(for senderType: SenderType) {
        switch senderType.alignment {
        case .leading:
            leadingConstraint?.priority = .required
            trailingConstraint?.priority = .defaultLow
            contentStackView.alignment = .leading
            actionStackView.alignment = .leading
            mediaContentStackView.alignment = .leading
            messageContentGroup.alignment = .leading
            timeLabel.textAlignment = .left

            if horizontalContainerStack.arrangedSubviews.first !== messageContentGroup {
                horizontalContainerStack.removeArrangedSubview(messageContentGroup)
                horizontalContainerStack.removeArrangedSubview(statusStackView)
                horizontalContainerStack.addArrangedSubview(messageContentGroup)
                horizontalContainerStack.addArrangedSubview(statusStackView)
            }

        case .trailing:
            leadingConstraint?.priority = .defaultLow
            trailingConstraint?.priority = .required
            contentStackView.alignment = .trailing
            actionStackView.alignment = .trailing
            mediaContentStackView.alignment = .trailing
            messageContentGroup.alignment = .trailing
            timeLabel.textAlignment = .right

            if horizontalContainerStack.arrangedSubviews.first !== statusStackView {
                horizontalContainerStack.removeArrangedSubview(statusStackView)
                horizontalContainerStack.removeArrangedSubview(messageContentGroup)
                horizontalContainerStack.addArrangedSubview(statusStackView)
                horizontalContainerStack.addArrangedSubview(messageContentGroup)
            }

        }

        updateBubblePadding(for: senderType)
    }

    private func updateContentLayout(
        hasText: Bool,
        hasMedia: Bool,
        senderType: SenderType
    ) {
        bubbleView.isHidden = !hasText
        mediaContentStackView.isHidden = !hasMedia
        messageContentGroup.isHidden = !hasText && !hasMedia
        currentHasMedia = hasMedia

        horizontalContainerStack.spacing = Layout.timeSpacingTight

        updateLayout(for: senderType)
    }

    private func updateProfileSpacing() {
        let profileSize = shouldReserveProfileSpace ? Layout.profileSize : 0
        profileImageView.snp.updateConstraints {
            $0.size.equalTo(profileSize)
        }
    }

    private func updateBubblePadding(for senderType: SenderType) {
        bubbleContentStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview().inset(Layout.textPadding)
        }
    }

    private func constrainMediaWidth(_ view: UIView) {
        view.snp.makeConstraints {
            $0.width.equalTo(Layout.maxContentWidth).priority(.high)
        }
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
            statusHintLabel.isHidden = !currentHasAttachments
        case .sent:
            actionStackView.isHidden = true
            statusHintLabel.isHidden = true
        }
    }

    @objc private func handleRetryTap() {
        guard let messageId = currentMessageId else { return }
        delegate?.chatMessageCellDidTapRetry(self, messageId: messageId)
    }

    @objc private func handleDeleteTap() {
        guard let messageId = currentMessageId else { return }
        delegate?.chatMessageCellDidTapDelete(self, messageId: messageId)
    }

    @objc private func handleProfileTap() {
        guard let userId = currentSenderUserId, !userId.isEmpty else { return }
        delegate?.chatMessageCell(self, didTapProfile: userId)
    }
}
