//
//  CommunityPostDetailViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import Combine
import SnapKit

final class CommunityPostDetailViewController: BaseViewController<CommunityPostDetailViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let creatorInfoView = CommunityCreatorInfoView()
    private let mediaBannerView = CommunityMediaBannerView()

    private var currentPostId: String?
    private var currentComments: [CommunityPostCommentEntity] = []
    private var currentPost: CommunityPostEntity?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        label.numberOfLines = 0
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1
        label.textColor = AppColor.gray90
        label.numberOfLines = 0
        return label
    }()

    private let likeButton: LikeButton = {
        let button = LikeButton()
        button.tintColor = AppColor.gray60
        return button
    }()

    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray75
        return label
    }()

    private let commentCountView = IconLabelView(
        icon: AppImage.chat,
        iconSize: 18,
        iconColor: AppColor.gray75,
        font: AppFont.caption1,
        textColor: AppColor.gray75
    )

    private lazy var interactionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [likeButton, likeCountLabel, commentCountView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let storeDetailCard = CommunityStoreDetailCard()
    private let commentsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.text = "댓글"
        return label
    }()

    private let commentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.medium
        return stackView
    }()

    private let dividerTop = Divider()
    private let dividerBottom = Divider()

    private let commentInputView = CommunityCommentInputView()
    private var commentInputBottomConstraint: Constraint?

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            creatorInfoView,
            mediaBannerView,
            titleLabel,
            contentLabel,
            interactionStackView,
            dividerTop,
            storeDetailCard,
            dividerBottom,
            commentsTitleLabel,
            commentsStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.large
        return stackView
    }()

    private enum Layout {
        static let bannerHeight: CGFloat = 240
        static let contentInset: CGFloat = AppSpacing.large
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = "게시글 상세"

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)
        view.addSubview(commentInputView)

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(commentInputView.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.contentInset)
        }

        mediaBannerView.snp.makeConstraints {
            $0.height.equalTo(Layout.bannerHeight)
        }

        storeDetailCard.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(120)
        }

        commentInputView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            commentInputBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }

        likeButton.snp.makeConstraints {
            $0.size.equalTo(18)
        }
        
        
        titleLabel.text = nil
        contentLabel.text = nil

        setupKeyboardObservers()
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        commentInputBottomConstraint?.update(offset: -keyboardHeight)

        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        commentInputBottomConstraint?.update(offset: 0)

        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let commentToggleSubject = PassthroughSubject<String, Never>()
        let likeToggleSubject = PassthroughSubject<Bool, Never>()
        let addCommentSubject = PassthroughSubject<(parentId: String?, content: String), Never>()
        let updateCommentSubject = PassthroughSubject<(commentId: String, content: String), Never>()
        let deleteCommentSubject = PassthroughSubject<String, Never>()
        let profileTappedSubject = PassthroughSubject<String, Never>()
        let commentContentTappedSubject = PassthroughSubject<String, Never>()

        let input = CommunityPostDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            commentToggleTapped: commentToggleSubject.eraseToAnyPublisher(),
            likeToggleTapped: likeToggleSubject.eraseToAnyPublisher(),
            addComment: addCommentSubject.eraseToAnyPublisher(),
            updateComment: updateCommentSubject.eraseToAnyPublisher(),
            deleteComment: deleteCommentSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.post
            .receive(on: DispatchQueue.main)
            .sink { [weak self] post in
                self?.applyPost(post)
            }
            .store(in: &cancellables)

        output.comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comments in
                self?.applyComments(
                    comments,
                    onToggle: { commentId in
                        commentToggleSubject.send(commentId)
                    },
                    onReply: { commentId, userName in
                        self?.handleReplyComment(commentId: commentId, userName: userName)
                    },
                    onEdit: { commentId, content in
                        self?.handleEditComment(commentId: commentId, content: content)
                    },
                    onDelete: { commentId in
                        self?.handleDeleteComment(commentId: commentId, deleteSubject: deleteCommentSubject)
                    },
                    onProfile: { userId in
                        profileTappedSubject.send(userId)
                    },
                    onContent: { commentId in
                        commentContentTappedSubject.send(commentId)
                    }
                )
            }
            .store(in: &cancellables)

        output.commentCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.commentCountView.updateText("\(count)개")
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "오류", message: message)
            }
            .store(in: &cancellables)

        mediaBannerView.isInteractionEnabled = true
        mediaBannerView.onVideoSelected = { [weak self] url in
            guard let self = self else { return }
            AppMediaService.shared.playVideo(url: url, from: self)
        }

        likeButton.tapPublisher
            .sink { event in
                likeToggleSubject.send(event.newState)
            }
            .store(in: &cancellables)

        commentInputView.configure(profileImageUrl: UserManager.shared.currentUser?.profileImage)
        commentInputView.onSendTapped = { [weak self] content in
            guard let self = self else { return }
            let mode = self.commentInputView.getCurrentMode()
            switch mode {
            case .normal:
                addCommentSubject.send((nil, content))
            case .reply(_, let parentId):
                addCommentSubject.send((parentId, content))
            case .edit(let commentId, _):
                updateCommentSubject.send((commentId, content))
            }
            self.commentInputView.setMode(.normal)
        }

        commentInputView.onCancelReply = { [weak self] in
            self?.commentInputView.setMode(.normal)
        }

        profileTappedSubject
            .sink { [weak self] userId in
                self?.viewModel.coordinator?.showUserProfile(userId: userId)
            }
            .store(in: &cancellables)

        commentContentTappedSubject
            .sink { [weak self] commentId in
                print("Comment tapped: \(commentId)")
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    private func applyPost(_ post: CommunityPostEntity?) {
        guard let post = post else { return }

        let isFirstLoad = currentPostId != post.postId
        currentPostId = post.postId
        currentPost = post

        if isFirstLoad {
            creatorInfoView.configure(
                name: post.creator.nick,
                createdAtText: post.createdAt?.toRelativeTime ?? "방금 전",
                profileImageUrl: post.creator.profileImage
            )

            creatorInfoView.onTap = { [weak self] in
                self?.viewModel.coordinator?.showUserProfile(userId: post.creator.userId)
            }

            titleLabel.text = post.title
            contentLabel.text = post.content

            let mediaItems = makeMediaItems(from: post.files)
            mediaBannerView.isHidden = mediaItems.isEmpty
            if !mediaItems.isEmpty {
                mediaBannerView.configure(items: mediaItems)
            }

            let reviewText = "리뷰 \(post.store.totalReviewCount)"
            let pickText = "픽 \(post.store.pickCount)"
            storeDetailCard.configure(
                storeName: post.store.name,
                ratingText: String(format: "%.1f", post.store.totalRating),
                reviewCountText: reviewText,
                pickCountText: pickText,
                isPickchelin: post.store.isPicchelin,
                tags: post.store.hashTags,
                imageUrl: post.store.storeImageUrls.first
            )

            storeDetailCard.onTap = { [weak self] in
                self?.viewModel.coordinator?.showStoreDetail(storeId: post.store.storeId)
            }
        }

        likeButton.configure(storeId: post.postId, isPicked: post.isLike)
        likeCountLabel.text = "\(post.likeCount)개"
    }

    private func makeMediaItems(from files: [String]) -> [CommunityMediaItemViewModel] {
        var results: [CommunityMediaItemViewModel] = []
        var pendingThumbnail: String?

        for (index, url) in files.enumerated() {
            let type = CommunityMediaType.from(url: url)

            if type == .video {
                let item = CommunityMediaItemViewModel(
                    url: url,
                    thumbnailUrl: pendingThumbnail,
                    type: .video
                )
                results.append(item)
                pendingThumbnail = nil
                continue
            }

            let isNextVideo: Bool = {
                guard index + 1 < files.count else { return false }
                return CommunityMediaType.from(url: files[index + 1]) == .video
            }()

            if isNextVideo {
                pendingThumbnail = url
                continue
            }

            results.append(
                CommunityMediaItemViewModel(
                    url: url,
                    thumbnailUrl: nil,
                    type: .image
                )
            )
        }

        return results
    }

    private func applyComments(
        _ comments: [CommunityPostCommentEntity],
        onToggle: @escaping (String) -> Void,
        onReply: @escaping (String, String) -> Void,
        onEdit: @escaping (String, String) -> Void,
        onDelete: @escaping (String) -> Void,
        onProfile: @escaping (String) -> Void,
        onContent: @escaping (String) -> Void
    ) {
        if shouldRebuildComments(comments) {
            commentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            comments.forEach { comment in
                let cell = CommunityCommentCell()
                cell.configure(comment: comment)
                cell.onToggleTapped = { commentId in
                    onToggle(commentId)
                }
                cell.onReplyTapped = { commentId, userName in
                    onReply(commentId, userName)
                }
                cell.onEditTapped = { commentId, content in
                    onEdit(commentId, content)
                }
                cell.onDeleteTapped = { commentId in
                    onDelete(commentId)
                }
                cell.onProfileTapped = { userId in
                    onProfile(userId)
                }
                cell.onContentTapped = { commentId in
                    onContent(commentId)
                }
                commentsStackView.addArrangedSubview(cell)
            }
            currentComments = comments
        } else {
            for (index, comment) in comments.enumerated() {
                guard index < commentsStackView.arrangedSubviews.count,
                      let cell = commentsStackView.arrangedSubviews[index] as? CommunityCommentCell else {
                    continue
                }
                if currentComments.count > index && currentComments[index].isExpanded != comment.isExpanded {
                    cell.configure(comment: comment)
                }
            }
            currentComments = comments
        }
    }

    private func shouldRebuildComments(_ comments: [CommunityPostCommentEntity]) -> Bool {
        guard comments.count == currentComments.count else { return true }

        for (index, comment) in comments.enumerated() {
            if currentComments[index].commentId != comment.commentId {
                return true
            }
            if currentComments[index].content != comment.content {
                return true
            }
            if currentComments[index].replies.count != comment.replies.count {
                return true
            }
        }
        return false
    }

    private func handleReplyComment(commentId: String, userName: String) {
        commentInputView.setMode(.reply(userName: userName, commentId: commentId))
        scrollToComment(commentId: commentId)
    }

    private func scrollToComment(commentId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            for view in self.commentsStackView.arrangedSubviews {
                guard let commentCell = view as? CommunityCommentCell else { continue }

                let cellFrameInScrollView = self.scrollView.convert(commentCell.frame, from: self.commentsStackView)
                let inputViewHeight = self.commentInputView.frame.height
                let visibleHeight = self.scrollView.bounds.height - inputViewHeight

                let targetY = cellFrameInScrollView.maxY - visibleHeight + 20

                if targetY > self.scrollView.contentOffset.y {
                    let maxOffset = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + inputViewHeight)
                    let finalOffset = min(targetY, maxOffset)

                    UIView.animate(withDuration: 0.3) {
                        self.scrollView.setContentOffset(CGPoint(x: 0, y: finalOffset), animated: false)
                    }
                }
                break
            }
        }
    }

    private func handleEditComment(commentId: String, content: String) {
        commentInputView.setMode(.edit(commentId: commentId, originalContent: content))
    }

    private func handleDeleteComment(commentId: String, deleteSubject: PassthroughSubject<String, Never>) {
        let alert = UIAlertController(
            title: "댓글 삭제",
            message: "정말로 이 댓글을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
            deleteSubject.send(commentId)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}
