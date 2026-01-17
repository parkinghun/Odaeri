//
//  CommunityReplyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityReplyView: UIView {
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 12
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2Medium
        label.textColor = AppColor.gray90
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2
        label.textColor = AppColor.gray60
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray90
        label.numberOfLines = 0
        return label
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerStackView, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, contentStackView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .top
        return stackView
    }()

    private enum Layout {
        static let profileSize: CGFloat = 24
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(mainStackView)
        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.profileSize)
        }
    }

    func configure(reply: CommunityPostReplyEntity) {
        nameLabel.text = reply.creator.nick
        timeLabel.text = reply.createdAt?.toRelativeTime ?? "방금 전"
        contentLabel.text = reply.content
        profileImageView.setImage(url: reply.creator.profileImage)
    }
}
