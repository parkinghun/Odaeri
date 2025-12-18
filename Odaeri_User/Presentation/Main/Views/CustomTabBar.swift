//
//  CustomTabBar.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int)
}

final class CustomTabBar: UIView {
    weak var delegate: CustomTabBarDelegate?

    private var selectedIndex: Int = 0 {
        didSet {
            updateTabSelection()
        }
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()

    private lazy var homeButton = createTabButton(
        emptyImage: AppImage.homeEmpty,
        fillImage: AppImage.homeFill,
        tag: 0
    )

    private lazy var orderButton = createTabButton(
        emptyImage: AppImage.orderEmpty,
        fillImage: AppImage.orderFill,
        tag: 1
    )

    private lazy var pickButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = AppColor.blackSprout
        button.setImage(AppImage.pickEmpty, for: .normal)
        button.tintColor = AppColor.gray0
        button.layer.cornerRadius = 32
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.addTarget(self, action: #selector(pickButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var communityButton = createTabButton(
        emptyImage: AppImage.communityEmpty,
        fillImage: AppImage.communityFill,
        tag: 3
    )

    private lazy var profileButton = createTabButton(
        emptyImage: AppImage.profileEmpty,
        fillImage: AppImage.profileFill,
        tag: 4
    )

    private lazy var tabButtons: [UIButton] = [
        homeButton,
        orderButton,
        communityButton,
        profileButton
    ]

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

    func selectTab(at index: Int) {
        guard index != selectedIndex else { return }
        selectedIndex = index
    }
}

// MARK: - Setup

private extension CustomTabBar {
    func setupUI() {
        addSubview(containerView)

        tabButtons.forEach { containerView.addSubview($0) }
        containerView.addSubview(pickButton)

        updateTabSelection()
    }

    func layoutTabButtons() {
        let tabWidth = bounds.width / 5
        let buttonSize: CGFloat = 24
        let pickButtonSize: CGFloat = 64
        let bottomInset: CGFloat = 8

        homeButton.frame = CGRect(
            x: tabWidth * 0 + (tabWidth - buttonSize) / 2,
            y: bounds.height - buttonSize - bottomInset - safeAreaInsets.bottom,
            width: buttonSize,
            height: buttonSize
        )

        orderButton.frame = CGRect(
            x: tabWidth * 1 + (tabWidth - buttonSize) / 2,
            y: bounds.height - buttonSize - bottomInset - safeAreaInsets.bottom,
            width: buttonSize,
            height: buttonSize
        )

        pickButton.frame = CGRect(
            x: tabWidth * 2 + (tabWidth - pickButtonSize) / 2,
            y: bounds.height - pickButtonSize - bottomInset - safeAreaInsets.bottom - 20,
            width: pickButtonSize,
            height: pickButtonSize
        )

        communityButton.frame = CGRect(
            x: tabWidth * 3 + (tabWidth - buttonSize) / 2,
            y: bounds.height - buttonSize - bottomInset - safeAreaInsets.bottom,
            width: buttonSize,
            height: buttonSize
        )

        profileButton.frame = CGRect(
            x: tabWidth * 4 + (tabWidth - buttonSize) / 2,
            y: bounds.height - buttonSize - bottomInset - safeAreaInsets.bottom,
            width: buttonSize,
            height: buttonSize
        )
    }

    func createTabButton(emptyImage: UIImage?, fillImage: UIImage?, tag: Int) -> UIButton {
        let button = UIButton()
        button.setImage(emptyImage, for: .normal)
        button.setImage(fillImage, for: .selected)
        button.tintColor = AppColor.gray60
        button.tag = tag
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    func updateTabSelection() {
        tabButtons.forEach { button in
            let isSelected = button.tag == selectedIndex
            button.isSelected = isSelected
            button.tintColor = isSelected ? AppColor.blackSprout : AppColor.gray60
        }

        let isPickSelected = selectedIndex == 2
        pickButton.setImage(isPickSelected ? AppImage.pickFill : AppImage.pickEmpty, for: .normal)
    }
}

// MARK: - Actions

private extension CustomTabBar {
    @objc func tabButtonTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        delegate?.tabBar(self, didSelectItemAt: sender.tag)
    }

    @objc func pickButtonTapped() {
        selectedIndex = 2
        delegate?.tabBar(self, didSelectItemAt: 2)
    }
}
