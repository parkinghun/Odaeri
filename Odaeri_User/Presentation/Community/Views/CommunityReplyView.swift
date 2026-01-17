//
//  CommunityReplyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityReplyView: UIView {
    var onEditTapped: ((String, String) -> Void)?
    var onDeleteTapped: ((String) -> Void)?
    var onProfileTapped: ((String) -> Void)?
    var onContentTapped: ((String) -> Void)?

    private var currentCommentId: String?
    private var currentContent: String?
    private var currentCreatorId: String?
    private var isMine: Bool = false

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

    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(AppImage.moreHorizontal, for: .normal)
        button.tintColor = AppColor.gray60
        return button
    }()

    private let spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, timeLabel, spacerView, moreButton])
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

        moreButton.addTarget(self, action: #selector(handleMoreTapped), for: .touchUpInside)

        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfileTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileTapGesture)

        let contentTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContentTapped))
        contentLabel.isUserInteractionEnabled = true
        contentLabel.addGestureRecognizer(contentTapGesture)
    }

    func configure(reply: CommunityPostReplyEntity) {
        currentCommentId = reply.commentId
        currentContent = reply.content
        currentCreatorId = reply.creator.userId
        isMine = reply.isMine

        nameLabel.text = reply.creator.nick
        timeLabel.text = reply.createdAt?.toRelativeTime ?? "방금 전"
        contentLabel.text = reply.content
        profileImageView.setImage(url: reply.creator.profileImage)

        moreButton.isHidden = !reply.isMine
    }

    @objc private func handleMoreTapped() {
        guard let commentId = currentCommentId,
              let content = currentContent else { return }
        showMoreMenu(commentId: commentId, content: content)
    }

    private func showMoreMenu(commentId: String, content: String) {
        guard let viewController = findViewController() else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let editAction = UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in
            self?.onEditTapped?(commentId, content)
        }

        let deleteAction = UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
            self?.onDeleteTapped?(commentId)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        viewController.present(alert, animated: true)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }

    @objc private func handleProfileTapped() {
        guard let creatorId = currentCreatorId else { return }
        onProfileTapped?(creatorId)
    }

    @objc private func handleContentTapped() {
        guard let commentId = currentCommentId else { return }
        onContentTapped?(commentId)
    }
}
