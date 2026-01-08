//
//  OrderPastCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class OrderPastCell: BaseCollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray75
        return label
    }()

    private let orderCodeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.gray60
        return label
    }()

    private let orderDateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.gray45
        return label
    }()

    private let menuSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3Bold
        label.textColor = AppColor.gray60
        return label
    }()

    private let priceButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(AppColor.blackSprout, for: .normal)
        button.titleLabel?.font = AppFont.body3Bold
        
        let resizedImage = AppImage.cheveronRight
            .resize(to: CGSize(width: 16, height: 16))
            .withRenderingMode(.alwaysTemplate)
        button.setImage(resizedImage, for: .normal)
        button.tintColor = AppColor.blackSprout
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: AppSpacing.tiny, bottom: 0, right: 0)
        return button
    }()

    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let reviewButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColor.gray30.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        return button
    }()

    override func setupUI() {
        super.setupUI()
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)

        containerView.addSubview(storeNameLabel)
        containerView.addSubview(orderCodeLabel)
        containerView.addSubview(orderDateLabel)
        containerView.addSubview(menuSummaryLabel)
        containerView.addSubview(priceButton)
        containerView.addSubview(storeImageView)
        containerView.addSubview(reviewButton)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        storeNameLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(AppSpacing.large)
            $0.trailing.lessThanOrEqualTo(storeImageView.snp.leading).offset(-AppSpacing.small)
        }

        orderCodeLabel.snp.makeConstraints {
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(AppSpacing.small)
            $0.leading.equalTo(storeNameLabel)
        }

        orderDateLabel.snp.makeConstraints {
            $0.leading.equalTo(orderCodeLabel.snp.trailing).offset(AppSpacing.medium)
            $0.centerY.equalTo(orderCodeLabel)
        }

        menuSummaryLabel.snp.makeConstraints {
            $0.top.equalTo(orderCodeLabel.snp.bottom).offset(AppSpacing.small)
            $0.leading.equalTo(storeNameLabel)
            $0.trailing.lessThanOrEqualTo(priceButton.snp.leading).offset(-AppSpacing.small)
        }

        priceButton.snp.makeConstraints {
            $0.leading.equalTo(menuSummaryLabel.snp.trailing).offset(AppSpacing.medium)
            $0.top.equalTo(menuSummaryLabel)
            $0.trailing.lessThanOrEqualTo(storeImageView.snp.leading).offset(-AppSpacing.small)
        }

        storeImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(AppSpacing.medium)
            $0.trailing.equalToSuperview().inset(AppSpacing.medium)
            $0.size.equalTo(80)
        }

        reviewButton.snp.makeConstraints {
            $0.top.equalTo(storeImageView.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.bottom.equalToSuperview().inset(AppSpacing.large)
            $0.height.equalTo(40)
        }
    }

    func configure(with display: OrderPastDisplay) {
        storeNameLabel.text = display.storeName
        orderCodeLabel.text = display.orderCodeText
        orderDateLabel.text = display.orderDateText
        menuSummaryLabel.text = display.menuSummaryText
        priceButton.setTitle(display.priceText, for: .normal)
        storeImageView.setImage(url: display.storeImageUrl)

        if let review = display.review {
            let starImage = AppImage.starFill.resize(to: CGSize(width: 20, height: 20))
            reviewButton.setImage(starImage, for: .normal)
            reviewButton.tintColor = AppColor.brightForsythia
            reviewButton.setTitle(review.ratingText, for: .normal)
            reviewButton.setTitleColor(AppColor.gray75, for: .normal)
            reviewButton.titleLabel?.font = AppFont.body1Bold
            reviewButton.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: AppSpacing.smallMedium,
                bottom: 0,
                right: 0
            )
            reviewButton.imageEdgeInsets = .zero
        } else {
            reviewButton.setImage(nil, for: .normal)
            reviewButton.setTitle("리뷰 작성", for: .normal)
            reviewButton.setTitleColor(AppColor.gray45, for: .normal)
            reviewButton.titleLabel?.font = AppFont.body1Bold
            reviewButton.titleEdgeInsets = .zero
        }
    }
}
