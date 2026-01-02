//
//  PopularShopCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import UIKit
import SnapKit
import Combine

final class PopularShopCell: BaseCollectionViewCell {
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()
    
    private let likeButton = LikeButton()
    var likeTapPublisher: AnyPublisher<LikeButton.TapEvent, Never> {
        likeButton.tapPublisher.eraseToAnyPublisher()
    }
    
    private let picchelinImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.pickchelin
        view.contentMode = .scaleAspectFill
        view.isHidden = true
        return view
    }()
    
    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3Bold
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
        label.font = AppFont.body3Bold
        label.textColor = AppColor.gray100
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
        label.font = AppFont.body3
        label.textColor = AppColor.gray75
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
        label.font = AppFont.body3
        label.textColor = AppColor.gray75
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
        label.font = AppFont.body3
        label.textColor = AppColor.gray75
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.resetImage()
    }
    
    override func setupUI() {
        contentView.backgroundColor = AppColor.gray15
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(likeButton)
        contentView.addSubview(infoContainerView)
        
        imageView.addSubview(picchelinImageView)
        
        infoContainerView.addSubview(nameLabel)
        infoContainerView.addSubview(likeIconImageView)
        infoContainerView.addSubview(likeCountLabel)
        infoContainerView.addSubview(distanceIconImageView)
        infoContainerView.addSubview(distanceLabel)
        infoContainerView.addSubview(timeIconImageView)
        infoContainerView.addSubview(timeLabel)
        infoContainerView.addSubview(runIconImageView)
        infoContainerView.addSubview(runLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.leading).offset(8)
            make.top.equalTo(imageView.snp.top).offset(8)
            make.width.height.equalTo(24)
        }
        
        picchelinImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(AppSpacing.small)
            make.width.equalTo(61)
            make.height.equalTo(32)
        }
        
        infoContainerView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.small)
            make.leading.equalToSuperview().offset(AppSpacing.smallMedium)
        }
        
        likeIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(AppSpacing.medium)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(16)
        }

        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(nameLabel)
        }
        
        distanceIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppSpacing.smallMedium)
            make.bottom.equalToSuperview().inset(AppSpacing.smallMedium)
            make.size.equalTo(16)
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(distanceIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(distanceIconImageView)
        }
        
        timeIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(AppSpacing.large)
            make.centerY.equalTo(distanceIconImageView)
            make.width.height.equalTo(16)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(timeIconImageView)
        }
        
        runIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(AppSpacing.large)
            make.centerY.equalTo(timeIconImageView)
            make.width.height.equalTo(16)
        }
        
        runLabel.snp.makeConstraints { make in
            make.leading.equalTo(runIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(runIconImageView)
        }
    }
    
    func configure(with store: StoreEntity) {
        imageView.setImage(url: store.storeImageUrls.first)
        
        nameLabel.text = store.name
        likeCountLabel.text = "\(store.pickCount)개"
        
        likeButton.configure(storeId: store.storeId, isPicked: store.isPick)
        
        picchelinImageView.isHidden = !store.isPicchelin
        
        distanceLabel.text = "3.2km"
        timeLabel.text = store.close
        runLabel.text = "135회"
    }
    
    func revertLike() {
        likeButton.revert()
    }
}

