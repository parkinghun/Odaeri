//
//  StoreReviewStarRatingView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class StoreReviewStarRatingView: UIView {
    private var starImageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for _ in 0..<5 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = AppColor.brightForsythia
            imageView.snp.makeConstraints { $0.size.equalTo(14) }
            stackView.addArrangedSubview(imageView)
            starImageViews.append(imageView)
        }
    }

    func configure(rating: Int) {
        for (index, imageView) in starImageViews.enumerated() {
            let isFilled = index < rating
            imageView.image = isFilled ? AppImage.starFill : AppImage.starEmpty
            imageView.tintColor = isFilled ? AppColor.brightForsythia : AppColor.gray30
        }
    }
}
