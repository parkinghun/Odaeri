//
//  CustomTabBar.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: CustomTabBar, didSelect item: TabBarItem)
}

final class CustomTabBar: UIView {
    weak var delegate: CustomTabBarDelegate?

    private var selectedItem: TabBarItem = .home {
        didSet {
            updateTabSelection()
        }
    }

    private var tabButtons: [TabBarItem: UIButton] = [:]

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        layoutTabButtons()
    }

    func selectTab(_ item: TabBarItem) {
        guard item != selectedItem else { return }
        selectedItem = item
    }
}

// MARK: - Setup

private extension CustomTabBar {
    func setupUI() {
        addSubview(containerView)

        TabBarItem.allCases.forEach { item in
            let button = createTabButton(for: item)
            tabButtons[item] = button
            containerView.addSubview(button)
        }

        updateTabSelection()
    }

    func layoutTabButtons() {
        let tabWidth = bounds.width / CGFloat(TabBarItem.allCases.count)
        let buttonSize: CGFloat = 24
        let pickButtonSize: CGFloat = 64
        let bottomInset: CGFloat = 8

        TabBarItem.allCases.forEach { item in
            guard let button = tabButtons[item] else { return }

            let index = CGFloat(item.rawValue)

            if item.isSpecial {
                button.frame = CGRect(
                    x: tabWidth * index + (tabWidth - pickButtonSize) / 2,
                    y: bounds.height - pickButtonSize - bottomInset - safeAreaInsets.bottom - 20,
                    width: pickButtonSize,
                    height: pickButtonSize
                )
            } else {
                button.frame = CGRect(
                    x: tabWidth * index + (tabWidth - buttonSize) / 2,
                    y: bounds.height - buttonSize - bottomInset - safeAreaInsets.bottom,
                    width: buttonSize,
                    height: buttonSize
                )
            }
        }
    }

    func createTabButton(for item: TabBarItem) -> UIButton {
        let button = UIButton()

        if item.isSpecial {
            button.backgroundColor = AppColor.blackSprout
            button.setImage(item.fillImage, for: .normal)
            button.tintColor = AppColor.gray0
            button.layer.cornerRadius = 32
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.15
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 12
        } else {
            button.setImage(item.fillImage, for: .normal)
            button.setImage(item.fillImage, for: .selected)
            button.tintColor = AppColor.gray60
        }

        button.tag = item.rawValue
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    func updateTabSelection() {
        tabButtons.forEach { item, button in
            let isSelected = item == selectedItem

            if item.isSpecial {
                button.setImage(isSelected ? item.fillImage : item.emptyImage, for: .normal)
            } else {
                button.isSelected = isSelected
                button.tintColor = isSelected ? AppColor.blackSprout : AppColor.gray30
            }
        }
    }
}

// MARK: - Actions

private extension CustomTabBar {
    @objc func tabButtonTapped(_ sender: UIButton) {
        guard let item = TabBarItem(rawValue: sender.tag) else { return }
        selectedItem = item
        delegate?.tabBar(self, didSelect: item)
    }
}
