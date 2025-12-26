//
//  CategoryItemView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import SnapKit

final class CategoryItemView: BaseView {
    private let category: Category
    private var isSelected: Bool

    private lazy var imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = isSelected ? AppColor.blackSprout.cgColor : AppColor.gray30.cgColor
        return view
    }()

    private lazy var categoryImageView: UIImageView = {
        let imageView = UIImageView(image: category.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = isSelected ? AppColor.blackSprout : AppColor.gray60
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = category.title
        label.font = AppFont.body3
        label.textColor = isSelected ? AppColor.blackSprout : AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageContainerView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    init(category: Category, isSelected: Bool = false) {
        self.category = category
        self.isSelected = isSelected
        super.init(frame: .zero)
    }

    override func setupView() {
        addSubview(stackView)
        imageContainerView.addSubview(categoryImageView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        imageContainerView.snp.makeConstraints {
            $0.size.equalTo(56)
        }

        categoryImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(32)
        }
    }

    func setSelected(_ selected: Bool) {
        isSelected = selected
        imageContainerView.layer.borderColor = selected ? AppColor.blackSprout.cgColor : AppColor.gray30.cgColor
        categoryImageView.tintColor = selected ? AppColor.blackSprout : AppColor.gray30
        titleLabel.textColor = selected ? AppColor.blackSprout : AppColor.gray60
    }
}
