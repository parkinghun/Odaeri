//
//  ChatMessageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
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

    private let rootStackView = UIStackView()
    private let contentStackView = UIStackView()
    private let bubbleRowStackView = UIStackView()

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let bubbleCornerRadius: CGFloat = 16
        static let horizontalSpacing: CGFloat = AppSpacing.small
        static let verticalSpacing: CGFloat = AppSpacing.xSmall
        static let contentInset: CGFloat = AppSpacing.large
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
        profileImageView.image = nil
        nameLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let dynamicRadius = min(bubbleView.frame.height / 2, Layout.bubbleCornerRadius)
        bubbleView.layer.cornerRadius = dynamicRadius
    }

    func configure(with model: ChatDisplayModel) {
        messageLabel.text = model.content
        nameLabel.text = model.senderName
        timeLabel.text = model.timeText

        nameLabel.isHidden = !model.showName
        timeLabel.isHidden = !model.showTime

        profileImageView.isHidden = !model.showProfile
        if model.showProfile, let urlString = model.senderProfileImageUrl {
            profileImageView.setImage(url: urlString, placeholder: AppImage.person)
        } else {
            profileImageView.image = AppImage.person
        }

        applyStyle(for: model.senderType)
        updateLayout(for: model.senderType)
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

        messageLabel.font = AppFont.body2
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        timeLabel.font = AppFont.caption2
        timeLabel.textColor = AppColor.gray60
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        rootStackView.axis = .horizontal
        rootStackView.alignment = .top
        rootStackView.spacing = Layout.horizontalSpacing

        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = Layout.verticalSpacing

        bubbleRowStackView.axis = .horizontal
        bubbleRowStackView.alignment = .bottom
        bubbleRowStackView.spacing = 4

        contentView.addSubview(rootStackView)
        rootStackView.addArrangedSubview(profileImageView)
        rootStackView.addArrangedSubview(contentStackView)

        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(bubbleRowStackView)

        bubbleRowStackView.addArrangedSubview(timeLabel)
        bubbleRowStackView.addArrangedSubview(bubbleView)

        bubbleView.addSubview(messageLabel)
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

        messageLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
    }

    private func applyStyle(for senderType: SenderType) {
        bubbleView.backgroundColor = senderType.bubbleBackgroundColor
        messageLabel.textColor = senderType.textColor
    }

    private func updateLayout(for senderType: SenderType) {
        switch senderType.alignment {
        case .leading:
            leadingConstraint?.priority = .required
            trailingConstraint?.priority = .defaultLow
            contentStackView.alignment = .leading

            if bubbleRowStackView.arrangedSubviews.first !== bubbleView {
                bubbleRowStackView.removeArrangedSubview(timeLabel)
                bubbleRowStackView.removeArrangedSubview(bubbleView)
                bubbleRowStackView.addArrangedSubview(bubbleView)
                bubbleRowStackView.addArrangedSubview(timeLabel)
            }

        case .trailing:
            leadingConstraint?.priority = .defaultLow
            trailingConstraint?.priority = .required
            contentStackView.alignment = .trailing

            if bubbleRowStackView.arrangedSubviews.first !== timeLabel {
                bubbleRowStackView.removeArrangedSubview(bubbleView)
                bubbleRowStackView.removeArrangedSubview(timeLabel)
                bubbleRowStackView.addArrangedSubview(timeLabel)
                bubbleRowStackView.addArrangedSubview(bubbleView)
            }
        }
    }
}
