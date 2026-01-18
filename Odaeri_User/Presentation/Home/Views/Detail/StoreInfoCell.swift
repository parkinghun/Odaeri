//
//  StoreInfoCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit
import SnapKit
import Combine

final class StoreInfoCell: BaseCollectionViewCell {
    var findRouteButtonTapPublisher: AnyPublisher<Void, Never> {
        findRouteButton.tapPublisher()
    }
    var reviewTapPublisher: AnyPublisher<Void, Never> {
        reviewTapButton.tapPublisher()
    }
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let picchelinImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.pickchelin
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let likeIconLabelView = IconLabelView(
        icon: AppImage.likeFill,
        iconColor: AppColor.brightForsythia,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private let rateIconLabelView = IconLabelView(
        icon: AppImage.starFill,
        iconColor: AppColor.brightForsythia,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private let rateCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Regular
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let reviewTapButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()

    private let orderIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.bike
        view.tintColor = AppColor.gray45
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let orderCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3
        label.textColor = AppColor.gray45
        return label
    }()

    private let detailInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let addressInfoRow = StoreInfoRowView()
    private let timeInfoRow = StoreInfoRowView()
    private let parkingInfoRow = StoreInfoRowView()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [addressInfoRow, timeInfoRow, parkingInfoRow])
        stackView.spacing = 13.5
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let estimatedTimeView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let estimatedTimeIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.run
        view.tintColor = AppColor.gray75
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let estimatedTimeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Regular
        label.textColor = AppColor.gray75
        return label
    }()

    private let findRouteButton: UIButton = {
        let button = UIButton()
        button.setTitle("길찾기", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.title1
        button.backgroundColor = AppColor.deepSprout
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()

    override func setupUI() {
        super.setupUI()
        contentView.addSubview(containerView)

        containerView.addSubview(nameLabel)
        containerView.addSubview(picchelinImageView)
        containerView.addSubview(likeIconLabelView)
        containerView.addSubview(rateIconLabelView)
        containerView.addSubview(rateCountLabel)
        containerView.addSubview(reviewTapButton)
        containerView.addSubview(orderIconImageView)
        containerView.addSubview(orderCountLabel)
        containerView.addSubview(detailInfoView)
        containerView.addSubview(estimatedTimeView)
        containerView.addSubview(findRouteButton)

        detailInfoView.addSubview(infoStackView)

        estimatedTimeView.addSubview(estimatedTimeIconImageView)
        estimatedTimeView.addSubview(estimatedTimeLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.xxxLarge)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        picchelinImageView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(AppSpacing.small)
            make.centerY.equalTo(nameLabel)
            make.width.equalTo(65)
            make.height.equalTo(34)
        }

        likeIconLabelView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppSpacing.medium)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        rateIconLabelView.snp.makeConstraints { make in
            make.centerY.equalTo(likeIconLabelView)
            make.leading.equalTo(likeIconLabelView.snp.trailing).offset(AppSpacing.medium)
        }

        rateCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(rateIconLabelView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(rateIconLabelView)
        }
        
        reviewTapButton.snp.makeConstraints { make in
            make.leading.equalTo(rateIconLabelView.snp.leading).offset(-AppSpacing.tiny)
            make.trailing.equalTo(rateCountLabel.snp.trailing).offset(AppSpacing.tiny)
            make.top.equalTo(rateIconLabelView.snp.top).offset(-AppSpacing.tiny)
            make.bottom.equalTo(rateIconLabelView.snp.bottom).offset(AppSpacing.tiny)
        }

        orderIconImageView.snp.makeConstraints { make in
            make.trailing.equalTo(orderCountLabel.snp.leading).offset(-AppSpacing.tiny)
            make.centerY.equalTo(rateIconLabelView)
            make.size.equalTo(20)
        }

        orderCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(orderIconImageView)
            make.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        detailInfoView.snp.makeConstraints { make in
            make.top.equalTo(likeIconLabelView.snp.bottom).offset(AppSpacing.medium)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        infoStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(AppSpacing.large)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        estimatedTimeView.snp.makeConstraints { make in
            make.top.equalTo(detailInfoView.snp.bottom).offset(AppSpacing.medium)
            make.leading.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        estimatedTimeIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        estimatedTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(estimatedTimeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.trailing.equalToSuperview().inset(AppSpacing.medium)
            make.top.bottom.equalToSuperview().inset(AppSpacing.small)
        }

        findRouteButton.snp.makeConstraints { make in
            make.top.equalTo(estimatedTimeView.snp.bottom).offset(AppSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(AppSpacing.large)
        }
    }

    func configure(with store: StoreEntity, estimatedTimeText: String) {
        nameLabel.text = store.name
        picchelinImageView.isHidden = !store.isPicchelin

        likeIconLabelView.updateText("\(store.pickCount)개")
        rateIconLabelView.updateText(store.rate)
        rateCountLabel.text = "(\(store.totalReviewCount))"
        orderCountLabel.text = "누적 주문 \(store.totalOrderCount)회"

        addressInfoRow.configure(info: .address, text: store.address)
        timeInfoRow.configure(info: .time, text: "매일 \(store.open) ~ \(store.close)")
        parkingInfoRow.configure(info: .parking, text: store.parkingGuide)

        estimatedTimeLabel.text = estimatedTimeText
    }
}
