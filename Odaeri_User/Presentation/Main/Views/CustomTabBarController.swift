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

    func selectTab(_ item: TabBarItem) {
        selectedIndex = item.rawValue
        customTabBar.selectTab(item)
    }

    override func setTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.customTabBar.alpha = hidden ? 0 : 1
                self.customTabBar.isHidden = hidden
            }
        } else {
            customTabBar.alpha = hidden ? 0 : 1
            customTabBar.isHidden = hidden
        }
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
    func tabBar(_ tabBar: CustomTabBar, didSelect item: TabBarItem) {
        selectedIndex = item.rawValue
    }
}
