//
//  StoreReviewCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class StoreReviewCell: UITableViewCell {
    static let reuseIdentifier = "StoreReviewCell"
    var cancellables = Set<AnyCancellable>()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        return view
    }()

    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray15
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        return label
    }()

    private let ratingView = StoreReviewStarRatingView()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray90
        label.numberOfLines = 0
        return label
    }()

    private let menuScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        return view
    }()

    private let menuChipStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let imageListView = StoreReviewImageListView()
    private var imageListHeightConstraint: Constraint?

    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(AppImage.moreHorizontal, for: .normal)
        button.tintColor = AppColor.gray60
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let profileTapButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()

    var profileTapPublisher: AnyPublisher<Void, Never> {
        profileTapButton.tapPublisher()
    }

    private lazy var nameTimeStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    var onMoreTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(nameTimeStack)
        containerView.addSubview(ratingView)
        containerView.addSubview(contentLabel)
        containerView.addSubview(menuScrollView)
        containerView.addSubview(imageListView)
        containerView.addSubview(moreButton)
        containerView.addSubview(separatorView)
        containerView.addSubview(profileTapButton)
        menuScrollView.addSubview(menuChipStackView)

        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.top.equalToSuperview().offset(AppSpacing.small)
            $0.bottom.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(AppSpacing.medium)
            $0.size.equalTo(36)
        }

        nameTimeStack.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(AppSpacing.small)
            $0.top.equalTo(profileImageView)
            $0.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-AppSpacing.small)
        }

        ratingView.snp.makeConstraints {
            $0.leading.equalTo(nameTimeStack)
            $0.top.equalTo(nameTimeStack.snp.bottom).offset(AppSpacing.xxSmall)
            $0.height.equalTo(16)
        }

        moreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.medium)
            $0.top.equalTo(profileImageView)
            $0.size.equalTo(24)
        }

        contentLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(AppSpacing.medium)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.medium)
        }

        menuScrollView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.equalTo(contentLabel)
            $0.height.equalTo(24)
        }

        menuChipStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        imageListView.snp.makeConstraints { make in
            make.top.equalTo(menuScrollView.snp.bottom).offset(AppSpacing.medium)
            make.leading.trailing.equalTo(contentLabel)
            imageListHeightConstraint = make.height.equalTo(88).constraint
            make.bottom.equalToSuperview().offset(-AppSpacing.medium)
        }

        separatorView.snp.makeConstraints {
            $0.leading.trailing.equalTo(contentLabel)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        profileTapButton.snp.makeConstraints {
            $0.leading.equalTo(profileImageView)
            $0.top.equalTo(profileImageView)
            $0.trailing.equalTo(nameTimeStack)
            $0.bottom.equalTo(ratingView)
        }

        moreButton.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
    }

    func configure(with item: StoreReviewItemViewModel) {
        nameLabel.text = item.creatorName
        timeLabel.text = item.createdAtText
        ratingView.configure(rating: item.rating)
        contentLabel.text = item.content
        updateMenuChips(item.menuList)
        profileImageView.setImage(url: item.creatorProfileUrl, placeholder: AppImage.person)
        moreButton.isHidden = !item.isMe

        if item.imageUrls.isEmpty {
            imageListView.isHidden = true
            imageListHeightConstraint?.update(offset: 0)
        } else {
            imageListView.isHidden = false
            imageListHeightConstraint?.update(offset: 88)
            imageListView.configure(imageUrls: item.imageUrls)
        }
    }

    @objc private func handleMoreTap() {
        onMoreTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        clearMenuChips()
    }
}

private extension StoreReviewCell {
    func updateMenuChips(_ menuList: [String]) {
        clearMenuChips()
        menuList.forEach { name in
            let label = StoreReviewMenuChipLabel()
            label.text = name
            menuChipStackView.addArrangedSubview(label)
        }
        menuScrollView.isHidden = menuList.isEmpty
    }

    func clearMenuChips() {
        menuChipStackView.arrangedSubviews.forEach { view in
            menuChipStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        menuScrollView.isHidden = true
    }
}

private final class StoreReviewMenuChipLabel: UILabel {
    private let inset = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = AppFont.caption2
        textColor = AppColor.gray75
        backgroundColor = AppColor.gray15
        layer.cornerRadius = 10
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: inset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + inset.left + inset.right, height: size.height + inset.top + inset.bottom)
    }
}
