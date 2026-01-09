//
//  ChatRoomListCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class ChatRoomListCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ChatRoomListCell.self)

    private let profileImageView = UIImageView()
    private let nicknameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadgeLabel = UILabel()
    private let unreadBadgeView = UIView()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nicknameLabel, lastMessageLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        return stackView
    }()

    private enum Layout {
        static let profileSize: CGFloat = 54
        static let badgeHeight: CGFloat = 18
        static let badgeMinWidth: CGFloat = 28
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
        nicknameLabel.text = nil
        lastMessageLabel.text = nil
        timeLabel.text = nil
        unreadBadgeView.isHidden = true
    }

    func configure(room: ChatRoomEntity, currentUserId: String?) {
        let opponent = room.participants.first { $0.userId != currentUserId } ?? room.participants.first

        nicknameLabel.text = opponent?.nick ?? "알 수 없음"
        profileImageView.resetImage(placeholder: AppImage.person)
        profileImageView.setImage(url: opponent?.profileImage, placeholder: AppImage.person)

        if let lastChat = room.lastChat {
            if lastChat.hasFiles {
                lastMessageLabel.text = "사진을 보냈습니다"
            } else {
                lastMessageLabel.text = lastChat.content
            }
            timeLabel.text = formatTimestamp(lastChat.createdAt)
        } else {
            lastMessageLabel.text = ""
            timeLabel.text = ""
        }
    }

    private func setupUI() {
        selectionStyle = .none

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = Layout.profileSize / 2
        profileImageView.backgroundColor = AppColor.gray15

        nicknameLabel.font = AppFont.body2Bold
        nicknameLabel.textColor = AppColor.gray75
        nicknameLabel.numberOfLines = 1

        lastMessageLabel.font = AppFont.body3
        lastMessageLabel.textColor = AppColor.gray60
        lastMessageLabel.numberOfLines = 1
        lastMessageLabel.lineBreakMode = .byTruncatingTail

        timeLabel.font = AppFont.caption
        timeLabel.textColor = AppColor.gray45
        timeLabel.textAlignment = .right

        unreadBadgeLabel.font = AppFont.caption2SemiBold
        unreadBadgeLabel.textColor = AppColor.gray0
        unreadBadgeLabel.textAlignment = .center

        unreadBadgeView.backgroundColor = AppColor.brightForsythia
        unreadBadgeView.layer.cornerRadius = Layout.badgeHeight / 2
        unreadBadgeView.isHidden = true

        contentView.addSubview(profileImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadgeView)
        unreadBadgeView.addSubview(unreadBadgeLabel)

        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(AppSpacing.large)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.profileSize)
        }

        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-AppSpacing.large)
            $0.top.equalToSuperview().offset(AppSpacing.medium)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(AppSpacing.medium)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-AppSpacing.small)
            $0.centerY.equalToSuperview()
        }

        unreadBadgeView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-AppSpacing.large)
            $0.bottom.equalToSuperview().offset(-AppSpacing.medium)
            $0.height.equalTo(Layout.badgeHeight)
            $0.width.greaterThanOrEqualTo(Layout.badgeMinWidth)
        }

        unreadBadgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.xSmall)
        }
    }

    private func formatTimestamp(_ value: String) -> String {
        guard let date = value.toDate() else { return "" }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.toTimeDisplay
        }
        if calendar.isDateInYesterday(date) {
            return "어제"
        }
        return Self.monthDayFormatter.string(from: date)
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()
}
