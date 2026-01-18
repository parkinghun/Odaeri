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
        var configuration = UIButton.Configuration.plain()

        let resizedImage = AppImage.cheveronRight
            .resize(to: CGSize(width: 12, height: 12))
            .withRenderingMode(.alwaysTemplate)
        
        configuration.image = resizedImage
        configuration.imagePlacement = .trailing
        configuration.imagePadding = AppSpacing.tiny
        configuration.baseForegroundColor = AppColor.blackSprout
        
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body3Bold
            return outgoing
        }
        
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        return button
    }()

    var onPriceTapped: (() -> Void)?
    
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
        var configuration = UIButton.Configuration.plain()
        
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 6,
            leading: 8,
            bottom: 6,
            trailing: 8
        )
        
        let button = UIButton(configuration: configuration)
        
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColor.gray30.cgColor
        
        return button
    }()

    var onStoreTapped: (() -> Void)?
    var onReviewTapped: (() -> Void)?

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

        storeNameLabel.isUserInteractionEnabled = true
        storeImageView.isUserInteractionEnabled = true
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(handleStoreTap))
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(handleStoreTap))
        storeNameLabel.addGestureRecognizer(nameTap)
        storeImageView.addGestureRecognizer(imageTap)
        priceButton.addTarget(self, action: #selector(handlePriceTap), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(handleReviewTap), for: .touchUpInside)
    }

    func configure(with display: OrderPastDisplay) {
        storeNameLabel.text = display.storeName
        orderCodeLabel.text = display.orderCodeText
        orderDateLabel.text = display.orderDateText
        menuSummaryLabel.text = display.menuSummaryText
        priceButton.setTitle(display.priceText, for: .normal)
        storeImageView.setImage(url: display.storeImageUrl)

        var config = reviewButton.configuration ?? UIButton.Configuration.plain()
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body1Bold
            return outgoing
        }

        if let review = display.review {
            let starImage = AppImage.starFill
                .resize(to: CGSize(width: 20, height: 20))
                .withRenderingMode(.alwaysTemplate)
            
            config.image = starImage
            config.imagePadding = AppSpacing.smallMedium
            config.imagePlacement = .leading
            
            config.title = review.ratingText
            config.baseForegroundColor = AppColor.gray75
            reviewButton.tintColor = AppColor.brightForsythia
            reviewButton.layer.borderColor = AppColor.gray30.cgColor
            
        } else {
            config.image = nil
            config.title = "리뷰 작성"
            config.baseForegroundColor = AppColor.deepSprout
            reviewButton.layer.borderColor = AppColor.deepSprout.cgColor
        }

        reviewButton.configuration = config
    }

    @objc private func handlePriceTap() {
        onPriceTapped?()
    }

    @objc private func handleStoreTap() {
        onStoreTapped?()
    }

    @objc private func handleReviewTap() {
        onReviewTapped?()
    }
}
