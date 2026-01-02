//
//  BannerCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import UIKit
import SnapKit

final class BannerCell: BaseCollectionViewCell {

    private let bannerImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let pageIndicatorContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray75.withAlphaComponent(0.5)
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray60.cgColor
        return view
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2Medium
        label.textColor = AppColor.gray30
        label.textAlignment = .center
        return label
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.resetImage()
    }

    override func setupUI() {
        contentView.backgroundColor = AppColor.gray15

        contentView.addSubview(bannerImageView)
        contentView.addSubview(pageIndicatorContainer)
        pageIndicatorContainer.addSubview(pageLabel)

        bannerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageIndicatorContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppSpacing.xLarge)
            make.bottom.equalToSuperview().inset(AppSpacing.medium)
            make.height.equalTo(20)
        }

        pageLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.smallMedium)
        }
    }

    func configure(with banner: BannerEntity, currentIndex: Int, totalCount: Int) {
        bannerImageView.setImage(url: banner.imageUrl)
        pageLabel.text = "\(currentIndex + 1) / \(totalCount)"
    }
}
