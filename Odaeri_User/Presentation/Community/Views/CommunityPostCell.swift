//
//  CommunityPostCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit

final class CommunityPostCell: UITableViewCell {
    static let reuseIdentifier = String(describing: CommunityPostCell.self)

    var cancellables = Set<AnyCancellable>()

    var likeTapPublisher: AnyPublisher<LikeButton.TapEvent, Never> {
        mediaGridView.likeTapPublisher
    }

    var onVideoSelected: ((URL) -> Void)? {
        didSet { mediaGridView.onVideoSelected = onVideoSelected }
    }

    var onStoreInfoTapped: ((String) -> Void)?
    var onCreatorTapped: ((String) -> Void)?

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let creatorInfoView = CommunityCreatorInfoView()
    private let mediaGridView = CommunityMediaGridView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let likeInfoView = IconLabelView(
        icon: AppImage.likeFill,
        iconSize: 20,
        iconColor: AppColor.brightForsythia,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private let distanceInfoView = IconLabelView(
        icon: AppImage.distance,
        iconSize: 20,
        iconColor: AppColor.blackSprout,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, likeInfoView, distanceInfoView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.numberOfLines = 0
        return label
    }()

    private let storeInfoView = CommunityStoreInfoView()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private var currentLikeCount: Int = 0
    private var currentStoreId: String?
    private var currentCreatorId: String?

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [creatorInfoView, mediaGridView, titleStackView, contentLabel, storeInfoView]
        )
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.medium
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        mediaGridView.reset()
    }

    private func setupUI() {
        selectionStyle = .none

        contentView.addSubview(cardView)
        contentView.addSubview(dividerView)
        cardView.addSubview(contentStackView)

        creatorInfoView.isUserInteractionEnabled = true
        let creatorTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCreatorTap))
        creatorInfoView.addGestureRecognizer(creatorTapGesture)

        storeInfoView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleStoreTap))
        storeInfoView.addGestureRecognizer(tapGesture)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(AppSpacing.xLarge)
        }

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.large)
        }

        dividerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        contentStackView.setCustomSpacing(AppSpacing.small, after: titleStackView)
        contentStackView.setCustomSpacing(AppSpacing.small, after: contentLabel)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        likeInfoView.setContentCompressionResistancePriority(.required, for: .horizontal)
        distanceInfoView.setContentCompressionResistancePriority(.required, for: .horizontal)
        likeInfoView.setContentHuggingPriority(.required, for: .horizontal)
        distanceInfoView.setContentHuggingPriority(.required, for: .horizontal)
    }

    func configure(with viewModel: CommunityPostItemViewModel) {
        currentLikeCount = viewModel.likeCountValue
        currentStoreId = viewModel.storeId
        currentCreatorId = viewModel.creatorUserId
        creatorInfoView.configure(
            name: viewModel.creatorName,
            createdAtText: viewModel.createdAtText,
            profileImageUrl: viewModel.creatorProfileImageUrl
        )
        mediaGridView.isHidden = viewModel.mediaItems.isEmpty
        if !viewModel.mediaItems.isEmpty {
            mediaGridView.configure(
                items: viewModel.mediaItems,
                postId: viewModel.postId,
                isLiked: viewModel.isLiked
            )
        }

        titleLabel.text = viewModel.title
        likeInfoView.updateText(viewModel.likeCountText)
        distanceInfoView.updateText(viewModel.distanceText)
        contentLabel.text = viewModel.content

        storeInfoView.configure(
            name: viewModel.storeName,
            infoText: viewModel.storeInfoText,
            imageUrl: viewModel.storeImageUrl
        )

        mediaGridView.likeTapPublisher
            .sink { [weak self] event in
                self?.applyOptimisticLike(isLiked: event.newState)
            }
            .store(in: &cancellables)
    }

    private func applyOptimisticLike(isLiked: Bool) {
        currentLikeCount = max(0, currentLikeCount + (isLiked ? 1 : -1))
        likeInfoView.updateText("\(currentLikeCount)개")
    }

    @objc private func handleStoreTap() {
        guard let storeId = currentStoreId else { return }
        onStoreInfoTapped?(storeId)
    }

    @objc private func handleCreatorTap() {
        guard let creatorId = currentCreatorId else { return }
        onCreatorTapped?(creatorId)
    }
}
