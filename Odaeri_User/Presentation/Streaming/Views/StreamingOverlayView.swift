//
//  StreamingOverlayView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit
import SnapKit

final class StreamingOverlayView: UIView {
    var onLikeTapped: (() -> Void)?
    var onMoreTapped: (() -> Void)?

    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        button.setImage(AppImage.likeEmpty, for: .normal)
        return button
    }()

    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.textAlignment = .center
        return label
    }()

    private let viewCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1
        label.textColor = AppColor.gray0
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray0
        label.numberOfLines = 2
        return label
    }()

    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("더보기", for: .normal)
        button.titleLabel?.font = AppFont.caption1
        button.setTitleColor(AppColor.gray0, for: .normal)
        return button
    }()

    private let createdAtLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2
        label.textColor = AppColor.gray15
        return label
    }()

    private let rightStackView = UIStackView()
    private let bottomStackView = UIStackView()
    private let descriptionStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with display: StreamingVideoDisplay) {
        titleLabel.text = display.title
        descriptionLabel.text = display.description
        likeCountLabel.text = display.likeCountText
        viewCountLabel.text = display.viewCountText
        createdAtLabel.text = display.createdAtText
        let likeImage = display.isLiked ? AppImage.likeFill : AppImage.likeEmpty
        likeButton.setImage(likeImage, for: .normal)
        moreButton.isHidden = display.description.isEmpty
    }

    func setDescriptionExpanded(_ expanded: Bool) {
        descriptionLabel.numberOfLines = expanded ? 0 : 2
    }

    func updateLikeState(isLiked: Bool, likeCountText: String) {
        let likeImage = isLiked ? AppImage.likeFill : AppImage.likeEmpty
        likeButton.setImage(likeImage, for: .normal)
        likeCountLabel.text = likeCountText
    }

    private func setupUI() {
        backgroundColor = .clear

        rightStackView.axis = .vertical
        rightStackView.alignment = .center
        rightStackView.spacing = 12

        let likeStack = UIStackView(arrangedSubviews: [likeButton, likeCountLabel])
        likeStack.axis = .vertical
        likeStack.alignment = .center
        likeStack.spacing = 4

        let viewStack = UIStackView(arrangedSubviews: [viewCountLabel])
        viewStack.axis = .vertical
        viewStack.alignment = .center

        rightStackView.addArrangedSubview(likeStack)
        rightStackView.addArrangedSubview(viewStack)

        descriptionStackView.axis = .horizontal
        descriptionStackView.alignment = .top
        descriptionStackView.spacing = 8
        descriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        moreButton.setContentHuggingPriority(.required, for: .horizontal)
        descriptionStackView.addArrangedSubview(descriptionLabel)
        descriptionStackView.addArrangedSubview(moreButton)

        bottomStackView.axis = .vertical
        bottomStackView.alignment = .leading
        bottomStackView.spacing = 6
        bottomStackView.addArrangedSubview(titleLabel)
        bottomStackView.addArrangedSubview(descriptionStackView)
        bottomStackView.addArrangedSubview(createdAtLabel)

        addSubview(rightStackView)
        addSubview(bottomStackView)

        rightStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(60)
            make.centerY.equalToSuperview()
        }

        bottomStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(rightStackView.snp.leading).offset(-16)
            make.bottom.equalToSuperview().inset(24)
        }
    }

    private func setupActions() {
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
    }

    @objc private func likeTapped() {
        onLikeTapped?()
    }

    @objc private func moreTapped() {
        onMoreTapped?()
    }
}
