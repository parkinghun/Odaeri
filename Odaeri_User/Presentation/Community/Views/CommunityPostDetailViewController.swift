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

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
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

        titleLabel.text = nil
        contentLabel.text = nil
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let commentToggleSubject = PassthroughSubject<String, Never>()

        let input = CommunityPostDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            commentToggleTapped: commentToggleSubject.eraseToAnyPublisher()
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
                self?.applyComments(comments, onToggle: { commentId in
                    commentToggleSubject.send(commentId)
                })
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

        mediaBannerView.onVideoSelected = { [weak self] url in
            guard let self = self else { return }
            AppMediaService.shared.playVideo(url: url.absoluteString, from: self)
        }

        viewDidLoadSubject.send(())
    }

    private func applyPost(_ post: CommunityPostEntity?) {
        guard let post = post else { return }

        creatorInfoView.configure(
            name: post.creator.nick,
            createdAtText: post.createdAt?.toRelativeTime ?? "방금 전",
            profileImageUrl: post.creator.profileImage
        )

        titleLabel.text = post.title
        contentLabel.text = post.content

        likeButton.configure(storeId: post.postId, isPicked: post.isLike)
        likeCountLabel.text = "\(post.likeCount)개"
        commentCountView.updateText("\(post.comments.count)개")

        let mediaItems = post.files.map { url in
            CommunityMediaItemViewModel(
                url: url,
                thumbnailUrl: nil,
                type: CommunityMediaType.from(url: url)
            )
        }
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
    }

    private func applyComments(_ comments: [CommunityPostCommentEntity], onToggle: @escaping (String) -> Void) {
        commentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        comments.forEach { comment in
            let cell = CommunityCommentCell()
            cell.configure(comment: comment)
            cell.onToggleTapped = { commentId in
                onToggle(commentId)
            }
            commentsStackView.addArrangedSubview(cell)
        }
    }
}
