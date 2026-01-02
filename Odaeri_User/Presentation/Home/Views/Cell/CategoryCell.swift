//
//  CategoryCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import UIKit
import SnapKit
import Combine

final class CategoryCell: BaseCollectionViewCell {
    private let categoryView = CategoryView()

    var categoryTapPublisher: AnyPublisher<Category, Never> {
        categoryView.categoryTapPublisher
    }

    override func setupUI() {
        contentView.backgroundColor = AppColor.gray15
        contentView.layer.cornerRadius = 30
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true

        contentView.addSubview(categoryView)

        categoryView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}
