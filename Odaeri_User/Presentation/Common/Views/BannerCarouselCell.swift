//
//  BannerCarouselCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class BannerCarouselCell: BaseCollectionViewCell {
    private let bannerView = BannerCarouselView()

    override func setupUI() {
        contentView.addSubview(bannerView)
        bannerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(
        banners: [BannerEntity],
        onUserScrolled: ((Int) -> Void)?,
        onBannerSelected: ((BannerEntity) -> Void)?
    ) {
        bannerView.onUserScrolled = onUserScrolled
        bannerView.onBannerSelected = onBannerSelected
        bannerView.update(banners: banners)
    }

    func scrollToBanner(at index: Int) {
        bannerView.scrollToBanner(at: index)
    }
}
