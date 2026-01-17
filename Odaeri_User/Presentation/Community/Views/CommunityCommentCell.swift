//
//  CommunityCommentCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityCommentCell: UIView {
    var onToggleTapped: ((String) -> Void)?

    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 16
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
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
        label.font = AppFont.body2
        label.textColor = AppColor.gray90
        label.numberOfLines = 0
        return label
    }()

    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = AppFont.caption2
        button.setTitleColor(AppColor.gray60, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let repliesContainerView = UIView()

    private let repliesGuideView: UIView = {
        let view = UIView()
        return view
    }()

    private let guideVerticalLine: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let guideHorizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let repliesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private lazy var commentContentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerStackView, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        return stackView
    }()

    private lazy var commentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, commentContentStackView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .top
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [commentStackView, toggleButton, repliesContainerView])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private var currentCommentId: String?
    private var currentReplies: [CommunityPostReplyEntity] = []

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let replyIndent: CGFloat = 40
        static let guideLineWidth: CGFloat = 1
        static let guideHorizontalLength: CGFloat = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
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

        repliesContainerView.addSubview(repliesGuideView)
        repliesContainerView.addSubview(repliesStackView)

        repliesGuideView.addSubview(guideVerticalLine)
        repliesGuideView.addSubview(guideHorizontalLine)

        repliesGuideView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(Layout.replyIndent)
        }

        guideVerticalLine.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.replyIndent / 2)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(Layout.guideLineWidth)
        }

        guideHorizontalLine.snp.makeConstraints {
            $0.leading.equalTo(guideVerticalLine.snp.centerX)
            $0.top.equalToSuperview().offset(Layout.profileSize / 2)
            $0.width.equalTo(Layout.guideHorizontalLength)
            $0.height.equalTo(Layout.guideLineWidth)
        }

        repliesStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.replyIndent)
            $0.trailing.bottom.top.equalToSuperview()
        }

        repliesContainerView.isHidden = true
        toggleButton.isHidden = true
    }

    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(handleToggleTapped), for: .touchUpInside)
    }

    func configure(comment: CommunityPostCommentEntity) {
        currentCommentId = comment.commentId
        currentReplies = comment.replies

        nameLabel.text = comment.creator.nick
        timeLabel.text = comment.createdAt?.toRelativeTime ?? "방금 전"
        contentLabel.text = comment.content
        profileImageView.setImage(url: comment.creator.profileImage)

        let replyCount = comment.replies.count
        toggleButton.isHidden = replyCount == 0
        updateToggleTitle(isExpanded: comment.isExpanded, count: replyCount)
        updateReplies(isExpanded: comment.isExpanded)
    }

    private func updateToggleTitle(isExpanded: Bool, count: Int) {
        let title = isExpanded ? "── 답글 숨기기" : "── 답글 \(count)개 보기"
        toggleButton.setTitle(title, for: .normal)
    }

    private func updateReplies(isExpanded: Bool) {
        if isExpanded {
            if repliesStackView.arrangedSubviews.isEmpty {
                currentReplies.forEach { reply in
                    let view = CommunityReplyView()
                    view.configure(reply: reply)
                    repliesStackView.addArrangedSubview(view)
                }
            }
        } else {
            repliesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }

        UIView.animate(withDuration: 0.2) {
            self.repliesContainerView.isHidden = !isExpanded
            self.layoutIfNeeded()
        }
    }

    @objc private func handleToggleTapped() {
        guard let commentId = currentCommentId else { return }
        onToggleTapped?(commentId)
    }
}
