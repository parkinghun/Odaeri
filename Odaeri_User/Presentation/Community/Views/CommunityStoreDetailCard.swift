//
//  CommunityStoreDetailCard.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityStoreDetailCard: UIView {
    var onTap: (() -> Void)?

    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 12
        return view
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let ratingView = IconLabelView(
        icon: AppImage.starFill,
        iconSize: 18,
        iconColor: AppColor.brightForsythia,
        font: AppFont.caption1,
        textColor: AppColor.gray75
    )

    private let reviewCountView = IconLabelView(
        icon: AppImage.list,
        iconSize: 18,
        iconColor: AppColor.gray60,
        font: AppFont.caption1,
        textColor: AppColor.gray75
    )

    private let pickCountView = IconLabelView(
        icon: AppImage.likeFill,
        iconSize: 18,
        iconColor: AppColor.blackSprout,
        font: AppFont.caption1,
        textColor: AppColor.gray75
    )

    private let pickchelinImageView: UIImageView = {
        let view = UIImageView(image: AppImage.pickchelin)
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private lazy var ratingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [ratingView, reviewCountView, pickchelinImageView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let tagScrollView = UIScrollView()

    private lazy var tagStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeNameLabel, ratingStackView, pickCountView, tagScrollView])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private enum Layout {
        static let imageSize: CGFloat = 72
        static let cardInset: CGFloat = AppSpacing.large
        static let tagHeight: CGFloat = 28
        static let cardCornerRadius: CGFloat = 12
        static let cardBorderWidth: CGFloat = 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius
        layer.borderWidth = Layout.cardBorderWidth
        layer.borderColor = AppColor.gray30.cgColor
        clipsToBounds = true

        addSubview(storeImageView)
        addSubview(textStackView)

        tagScrollView.showsHorizontalScrollIndicator = false
        tagScrollView.addSubview(tagStackView)

        storeImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.imageSize)
            $0.leading.top.equalToSuperview().inset(Layout.cardInset)
            $0.bottom.lessThanOrEqualToSuperview().inset(Layout.cardInset)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(storeImageView.snp.trailing).offset(AppSpacing.large)
            $0.trailing.equalToSuperview().inset(Layout.cardInset)
            $0.centerY.equalTo(storeImageView.snp.centerY)
            $0.top.greaterThanOrEqualToSuperview().inset(Layout.cardInset)
            $0.bottom.lessThanOrEqualToSuperview().inset(Layout.cardInset)
        }

        tagScrollView.snp.makeConstraints {
            $0.height.equalTo(Layout.tagHeight)
        }

        tagStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        onTap?()
    }

    func configure(
        storeName: String,
        ratingText: String,
        reviewCountText: String,
        pickCountText: String,
        isPickchelin: Bool,
        tags: [String],
        imageUrl: String?
    ) {
        storeNameLabel.text = storeName
        ratingView.updateText(ratingText)
        reviewCountView.updateText(reviewCountText)
        pickCountView.updateText(pickCountText)
        pickchelinImageView.isHidden = !isPickchelin
        storeImageView.setImage(url: imageUrl)
        updateTags(tags)
    }

    private func updateTags(_ tags: [String]) {
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        tags.forEach { tag in
            let label = TagLabel()
            label.text = tag
            label.font = AppFont.caption2
            label.textColor = AppColor.gray75
            label.backgroundColor = AppColor.gray0
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.textAlignment = .center
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.snp.makeConstraints { $0.height.equalTo(24) }
            tagStackView.addArrangedSubview(label)
        }
    }
}

private final class TagLabel: UILabel {
    private let textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
