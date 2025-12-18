//
//  MainCoordinator.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit

protocol MainCoordinatorDelegate: AnyObject {
    func mainCoordinatorDidLogout(_ coordinator: MainCoordinator)
}

final class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: MainCoordinatorDelegate?

    private let tabBarController = CustomTabBarController()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let homeNav = createHomeTab()
        let orderNav = createOrderTab()
        let pickNav = createPickTab()
        let communityNav = createCommunityTab()
        let profileNav = createProfileTab()

        tabBarController.viewControllers = [
            homeNav,
            orderNav,
            pickNav,
            communityNav,
            profileNav
        ]

        navigationController.setViewControllers([tabBarController], animated: false)
        navigationController.isNavigationBarHidden = true
    }
}

// MARK: - Tab Creation

private extension MainCoordinator {
    func createHomeTab() -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0
        let label = UILabel()
        label.text = "Home"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        nav.setViewControllers([viewController], animated: false)
        return nav
    }

    func createOrderTab() -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0
        let label = UILabel()
        label.text = "Order"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        nav.setViewControllers([viewController], animated: false)
        return nav
    }

    func createPickTab() -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0
        let label = UILabel()
        label.text = "Pick"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        nav.setViewControllers([viewController], animated: false)
        return nav
    }

    func createCommunityTab() -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0
        let label = UILabel()
        label.text = "Community"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        nav.setViewControllers([viewController], animated: false)
        return nav
    }

    func createProfileTab() -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0
        let label = UILabel()
        label.text = "Profile"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        nav.setViewControllers([viewController], animated: false)
        return nav
    }
}
