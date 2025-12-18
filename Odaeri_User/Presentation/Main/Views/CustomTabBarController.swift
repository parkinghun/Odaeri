//
//  CustomTabBarController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit

final class CustomTabBarController: UITabBarController {
    private let customTabBar = CustomTabBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCustomTabBar()
    }

    func selectTab(at index: Int) {
        selectedIndex = index
        customTabBar.selectTab(at: index)
    }
}

// MARK: - Setup

private extension CustomTabBarController {
    func setupCustomTabBar() {
        tabBar.isHidden = true
        customTabBar.delegate = self
        view.addSubview(customTabBar)
    }

    func layoutCustomTabBar() {
        let tabBarHeight: CGFloat = 60 + view.safeAreaInsets.bottom
        customTabBar.frame = CGRect(
            x: 0,
            y: view.bounds.height - tabBarHeight,
            width: view.bounds.width,
            height: tabBarHeight
        )
    }
}

// MARK: - CustomTabBarDelegate

extension CustomTabBarController: CustomTabBarDelegate {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int) {
        selectedIndex = index
    }
}
