//
//  ChatRoomListCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import SnapKit

final class ChatRoomListCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ChatRoomListCell.self)

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let lastChatLabel = UILabel()
    private let timeLabel = UILabel()
    private let badgeLabel = UILabel()

    private let contentStackView = UIStackView()
    private let textStackView = UIStackView()
    private let bottomStackView = UIStackView()

    private enum Layout {
        static let profileSize: CGFloat = 44
        static let badgeMinWidth: CGFloat = 20
        static let badgeHeight: CGFloat = 20
        static let badgePadding: CGFloat = 6
        static let contentInset: CGFloat = AppSpacing.large
        static let horizontalSpacing: CGFloat = AppSpacing.medium
        static let verticalSpacing: CGFloat = AppSpacing.xSmall
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.resetImage(placeholder: AppImage.person)
        nameLabel.text = nil
        lastChatLabel.text = nil
        timeLabel.text = nil
        badgeLabel.isHidden = true
        badgeLabel.text = nil
    }

    func configure(with model: ChatRoomDisplayModel) {
        nameLabel.text = model.opponentName
        lastChatLabel.text = model.lastChatText
        timeLabel.text = model.lastChatTimeText

        if let urlString = model.opponentProfileImageUrl {
            profileImageView.setImage(
                url: urlString,
                placeholder: AppImage.person,
                animated: false,
                downsample: true
            )
        } else {
            profileImageView.image = AppImage.person
        }

        badgeLabel.isHidden = !model.hasUnread
        if model.hasUnread {
            badgeLabel.text = model.unreadBadgeText
        }
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = AppColor.gray0

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = Layout.profileSize / 2
        profileImageView.backgroundColor = AppColor.gray15

        nameLabel.font = AppFont.body1
        nameLabel.textColor = AppColor.gray90
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        lastChatLabel.font = AppFont.body3
        lastChatLabel.textColor = AppColor.gray60
        lastChatLabel.numberOfLines = 1
        lastChatLabel.lineBreakMode = .byTruncatingTail
        lastChatLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        timeLabel.font = AppFont.caption2
        timeLabel.textColor = AppColor.gray60
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        badgeLabel.font = AppFont.caption2
        badgeLabel.textColor = AppColor.gray0
        badgeLabel.backgroundColor = AppColor.blackSprout
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = Layout.badgeHeight / 2
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true

        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = Layout.horizontalSpacing

        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = Layout.verticalSpacing
        textStackView.distribution = .fill

        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .center
        bottomStackView.spacing = AppSpacing.xSmall

        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(profileImageView)
        contentStackView.addArrangedSubview(textStackView)
        contentStackView.addArrangedSubview(timeLabel)

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(bottomStackView)

        bottomStackView.addArrangedSubview(lastChatLabel)
        bottomStackView.addArrangedSubview(badgeLabel)
    }

    private func setupConstraints() {
        contentStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(AppSpacing.medium)
            $0.leading.trailing.equalToSuperview().inset(Layout.contentInset)
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.profileSize)
        }

        badgeLabel.snp.makeConstraints {
            $0.height.equalTo(Layout.badgeHeight)
            $0.width.greaterThanOrEqualTo(Layout.badgeMinWidth)
        }
    }
}
