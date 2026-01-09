//
//  ChatMessageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class ChatMessageCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ChatMessageCell.self)

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let thumbnailImageView = UIImageView()

    private var bubbleLeadingToProfileConstraint: Constraint?
    private var bubbleLeadingToContentConstraint: Constraint?
    private var bubbleTrailingLessConstraint: Constraint?
    private var bubbleTrailingEqualConstraint: Constraint?
    private var bubbleMaxWidthConstraint: Constraint?
    private var nameLeadingConstraint: Constraint?
    private var bubbleTopToNameConstraint: Constraint?
    private var bubbleTopToContentConstraint: Constraint?

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let bubbleInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let bubbleCornerRadius: CGFloat = 16
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.resetImage(placeholder: AppImage.person)
        nameLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
        thumbnailImageView.image = nil
    }

    func configure(with viewModel: ChatMessageCellViewModel, maxWidthRatio: CGFloat) {
        let isMe = viewModel.isMe

        nameLabel.text = viewModel.showName ? viewModel.nickname : nil
        nameLabel.isHidden = !viewModel.showName

        timeLabel.text = viewModel.showTime ? viewModel.timeText : nil
        timeLabel.isHidden = !viewModel.showTime
        timeLabel.textAlignment = isMe ? .right : .left

        profileImageView.isHidden = !viewModel.showProfile
        if viewModel.showProfile {
            profileImageView.resetImage(placeholder: AppImage.person)
            profileImageView.setImage(url: viewModel.profileImageUrl, placeholder: AppImage.person)
        }

        if viewModel.hasFiles {
            thumbnailImageView.isHidden = false
            messageLabel.isHidden = true
            thumbnailImageView.image = AppImage.default
        } else {
            thumbnailImageView.isHidden = true
            messageLabel.isHidden = false
            messageLabel.text = viewModel.message
        }

        bubbleView.backgroundColor = isMe ? AppColor.blackSprout : AppColor.gray15
        messageLabel.textColor = isMe ? AppColor.gray0 : AppColor.gray90

        updateLayout(isMe: isMe)
        updateMaxWidthRatio(maxWidthRatio)
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

        bubbleView.layer.cornerRadius = Layout.bubbleCornerRadius
        bubbleView.clipsToBounds = true

        messageLabel.font = AppFont.body2
        messageLabel.numberOfLines = 0

        timeLabel.font = AppFont.caption2
        timeLabel.textColor = AppColor.gray60

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true

        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(thumbnailImageView)

        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(AppSpacing.large)
            $0.top.equalToSuperview().offset(AppSpacing.small)
            $0.size.equalTo(Layout.profileSize)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.small)
            nameLeadingConstraint = $0.leading.equalTo(profileImageView.snp.trailing)
                .offset(AppSpacing.small)
                .constraint
            $0.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.large)
        }

        bubbleView.snp.makeConstraints {
            bubbleTopToNameConstraint = $0.top.equalTo(nameLabel.snp.bottom)
                .offset(AppSpacing.xSmall)
                .constraint
            bubbleTopToContentConstraint = $0.top.equalToSuperview()
                .offset(AppSpacing.small)
                .constraint
            bubbleLeadingToProfileConstraint = $0.leading.equalTo(profileImageView.snp.trailing)
                .offset(AppSpacing.small)
                .constraint
            bubbleLeadingToContentConstraint = $0.leading.greaterThanOrEqualToSuperview()
                .offset(AppSpacing.large)
                .constraint
            bubbleTrailingLessConstraint = $0.trailing.lessThanOrEqualToSuperview()
                .inset(60)
                .constraint
            bubbleTrailingEqualConstraint = $0.trailing.equalToSuperview()
                .inset(AppSpacing.large)
                .constraint
            bubbleMaxWidthConstraint = $0.width.lessThanOrEqualToSuperview()
                .multipliedBy(0.75)
                .constraint
        }
        bubbleLeadingToContentConstraint?.deactivate()
        bubbleTrailingEqualConstraint?.deactivate()
        bubbleTopToContentConstraint?.deactivate()

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(bubbleView.snp.bottom).offset(AppSpacing.xSmall)
            $0.bottom.equalToSuperview().inset(AppSpacing.small)
            $0.leading.equalTo(bubbleView.snp.leading)
            $0.trailing.equalTo(bubbleView.snp.trailing)
        }

        messageLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.bubbleInset)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(120)
            $0.width.greaterThanOrEqualTo(160)
        }
    }

    private func updateLayout(isMe: Bool) {
        if isMe {
            profileImageView.isHidden = true
            nameLabel.isHidden = true
            bubbleLeadingToProfileConstraint?.deactivate()
            bubbleTrailingLessConstraint?.deactivate()
            bubbleTopToNameConstraint?.deactivate()
            bubbleLeadingToContentConstraint?.activate()
            bubbleTrailingEqualConstraint?.activate()
            bubbleTopToContentConstraint?.activate()
        } else {
            profileImageView.isHidden = false
            nameLabel.isHidden = false
            bubbleLeadingToContentConstraint?.deactivate()
            bubbleTrailingEqualConstraint?.deactivate()
            bubbleTopToContentConstraint?.deactivate()
            bubbleLeadingToProfileConstraint?.activate()
            bubbleTrailingLessConstraint?.activate()
            bubbleTopToNameConstraint?.activate()
        }
    }

    private func updateMaxWidthRatio(_ ratio: CGFloat) {
        bubbleMaxWidthConstraint?.deactivate()
        bubbleView.snp.makeConstraints {
            bubbleMaxWidthConstraint = $0.width.lessThanOrEqualToSuperview()
                .multipliedBy(ratio)
                .constraint
        }
    }
}

struct ChatMessageCellViewModel {
    let message: String
    let nickname: String
    let profileImageUrl: String?
    let timeText: String
    let isMe: Bool
    let showProfile: Bool
    let showName: Bool
    let showTime: Bool
    let hasFiles: Bool
}
