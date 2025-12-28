//
//  CategoryView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class CategoryView: BaseView {
    private var selectedCategory: Category?

    private let tapSubject = PassthroughSubject<Category, Never>()
    var categoryTapPublisher: AnyPublisher<Category, Never> {
        tapSubject.eraseToAnyPublisher()
    }

    private lazy var categoryItems: [CategoryItemView] = {
        Category.allCases.map { category in
            let itemView = CategoryItemView(category: category)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(categoryTapped(_:)))
            itemView.addGestureRecognizer(tapGesture)
            itemView.isUserInteractionEnabled = true
            itemView.tag = Category.allCases.firstIndex(of: category) ?? 0
            return itemView
        }
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: categoryItems)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()

    override func setupView() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }
    }

    @objc private func categoryTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? CategoryItemView,
              let index = categoryItems.firstIndex(of: tappedView),
              index < Category.allCases.count else { return }

        let category = Category.allCases[index]

        categoryItems.forEach { $0.setSelected(false) }
        tappedView.setSelected(true)

        selectedCategory = category
        tapSubject.send(category)
    }

    func selectCategory(_ category: Category) {
        guard let index = Category.allCases.firstIndex(of: category) else { return }

        categoryItems.forEach { $0.setSelected(false) }
        categoryItems[index].setSelected(true)
        selectedCategory = category
    }
}
