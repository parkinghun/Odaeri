//
//  ShopListCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/29/25.
//

import UIKit
import SnapKit
import Combine
import CoreLocation

final class ShopListCell: BaseCollectionViewCell {
    
    private let mainImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.backgroundColor = AppColor.gray30
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let subImageView1: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.backgroundColor = AppColor.gray30
        return view
    }()
    
    private let subImageView2: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.backgroundColor = AppColor.gray30
        return view
    }()
    
    private let likeButton = LikeButton()
    var likeTapPublisher: AnyPublisher<LikeButton.TapEvent, Never> {
        likeButton.tapPublisher.eraseToAnyPublisher()
    }

    private var currentPickCount: Int = 0
    
    private let picchelinImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.pickchelin
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    private let infoContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray100
        return label
    }()
    
    private let likeIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.likeFill
        view.tintColor = AppColor.brightForsythia
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray100
        return label
    }()
    
    private let rateIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.starFill
        view.tintColor = AppColor.brightForsythia
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let rateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray100
        return label
    }()
    
    private let rateCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Regular
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let distanceIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.distance
        view.tintColor = AppColor.blackSprout
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Regular
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let timeIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.time
        view.tintColor = AppColor.blackSprout
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Regular
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let runIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.run
        view.tintColor = AppColor.blackSprout
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let runLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Regular
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let hashTagStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let bottomDivider = Divider(height: 1, color: AppColor.gray30)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainImageView.resetImage()
        subImageView1.resetImage()
        subImageView2.resetImage()
        hashTagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    override func setupUI() {
        contentView.backgroundColor = AppColor.gray15
        
        contentView.addSubview(mainImageView)
        contentView.addSubview(subImageView1)
        contentView.addSubview(subImageView2)
        
        mainImageView.addSubview(likeButton)
        mainImageView.addSubview(picchelinImageView)
        
        contentView.addSubview(infoContainerView)
        contentView.addSubview(bottomDivider)
        
        infoContainerView.addSubview(nameLabel)
        infoContainerView.addSubview(likeIconImageView)
        infoContainerView.addSubview(likeCountLabel)
        infoContainerView.addSubview(rateIconImageView)
        infoContainerView.addSubview(rateLabel)
        infoContainerView.addSubview(rateCountLabel)
        infoContainerView.addSubview(distanceIconImageView)
        infoContainerView.addSubview(distanceLabel)
        infoContainerView.addSubview(timeIconImageView)
        infoContainerView.addSubview(timeLabel)
        infoContainerView.addSubview(runIconImageView)
        infoContainerView.addSubview(runLabel)
        infoContainerView.addSubview(hashTagStackView)
        
        mainImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.small)
            make.leading.equalToSuperview().inset(AppSpacing.screenMargin)
            make.height.equalTo(127)
        }
        
        subImageView1.snp.makeConstraints { make in
            make.top.equalTo(mainImageView)
            make.leading.equalTo(mainImageView.snp.trailing).offset(AppSpacing.xSmall)
            make.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.width.equalTo(mainImageView.snp.width).multipliedBy(78.0 / 268.0)
            make.height.equalTo(mainImageView.snp.height).offset(-AppSpacing.xSmall / 2).dividedBy(2)
        }
        
        subImageView2.snp.makeConstraints { make in
            make.top.equalTo(subImageView1.snp.bottom).offset(AppSpacing.xSmall)
            make.leading.trailing.equalTo(subImageView1)
            make.bottom.equalTo(mainImageView)
        }
        
        likeButton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(AppSpacing.small)
            make.width.height.equalTo(24)
        }
        
        picchelinImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(AppSpacing.small)
            make.trailing.equalToSuperview().inset(AppSpacing.medium)
            make.width.equalTo(65)
            make.height.equalTo(34)
        }
        
        infoContainerView.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(AppSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        likeIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(AppSpacing.small)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(20)
        }
        
        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(nameLabel)
        }
        
        rateIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(likeCountLabel.snp.trailing).offset(AppSpacing.small)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(20)
        }
        
        rateLabel.snp.makeConstraints { make in
            make.leading.equalTo(rateIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(nameLabel)
        }
        rateCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(rateLabel.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(rateLabel)
        }
        
        distanceIconImageView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppSpacing.small)
            make.leading.equalToSuperview()
            make.size.equalTo(20)
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(distanceIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(distanceIconImageView)
        }
        
        timeIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(AppSpacing.large)
            make.centerY.equalTo(distanceIconImageView)
            make.size.equalTo(20)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(timeIconImageView)
        }
        
        runIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(AppSpacing.large)
            make.centerY.equalTo(timeIconImageView)
            make.size.equalTo(20)
        }
        
        runLabel.snp.makeConstraints { make in
            make.leading.equalTo(runIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(runIconImageView)
        }
        
        hashTagStackView.snp.makeConstraints { make in
            make.top.equalTo(distanceIconImageView.snp.bottom).offset(AppSpacing.small)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        bottomDivider.snp.makeConstraints { make in
            make.top.equalTo(hashTagStackView.snp.bottom).offset(AppSpacing.small)
            make.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.bottom.equalToSuperview()
        }
    }
    
    func configure(with store: StoreEntity, currentLocation: CLLocation?) {
        mainImageView.setImage(url: store.storeImageUrls.first)
        subImageView1.setImage(url: store.storeImageUrls.count > 1 ? store.storeImageUrls[1] : nil)
        subImageView2.setImage(url: store.storeImageUrls.count > 2 ? store.storeImageUrls[2] : nil)

        nameLabel.text = store.name
        currentPickCount = store.pickCount
        updateLikeCountLabel()

        rateLabel.text = String(format: "%.1f", store.totalRating)
        rateCountLabel.text = "(\(store.totalReviewCount))"

        likeButton.configure(storeId: store.storeId, isPicked: store.isPick)

        picchelinImageView.isHidden = !store.isPicchelin

        if let currentLocation = currentLocation {
            let distance = RouteManager.shared.calculateDistance(
                from: currentLocation.coordinate,
                to: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
            )
            distanceLabel.text = String(format: "%.1fkm", distance)

            let estimatedSteps = RouteManager.shared.calculateEstimatedSteps(distanceInKm: distance)
            runLabel.text = "\(estimatedSteps)보"
        } else {
            distanceLabel.text = "--km"
            runLabel.text = "--보"
        }

        timeLabel.text = store.close

        hashTagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for hashTag in store.hashTags {
            let containerView = UIView()
            containerView.backgroundColor = AppColor.deepSprout
            containerView.layer.cornerRadius = 8

            let hashTagLabel = UILabel()
            hashTagLabel.text = hashTag
            hashTagLabel.font = AppFont.caption
            hashTagLabel.textColor = AppColor.gray0

            containerView.addSubview(hashTagLabel)

            hashTagLabel.snp.makeConstraints { make in
                make.verticalEdges.equalToSuperview().inset(AppSpacing.xxSmall)
                make.horizontalEdges.equalToSuperview().inset(AppSpacing.small)
            }

            hashTagStackView.addArrangedSubview(containerView)
        }
    }
    
    func updateLikeCount(isPicked: Bool) {
        currentPickCount = max(0, currentPickCount + (isPicked ? 1 : -1))
        updateLikeCountLabel()
    }

    func revertLike() {
        likeButton.revert()
        updateLikeCount(isPicked: likeButton.isPicked)
    }

    private func updateLikeCountLabel() {
        likeCountLabel.text = "\(currentPickCount)개"
    }
}
