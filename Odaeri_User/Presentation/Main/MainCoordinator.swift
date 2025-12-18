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
        let viewControllers = TabBarItem.allCases.map { item in
            createTab(for: item)
        }

        tabBarController.viewControllers = viewControllers
        navigationController.setViewControllers([tabBarController], animated: false)
        navigationController.isNavigationBarHidden = true
    }
}

// MARK: - Tab Creation

private extension MainCoordinator {
    func createTab(for item: TabBarItem) -> UINavigationController {
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true

        let viewController = createViewController(for: item)
        nav.setViewControllers([viewController], animated: false)
        return nav
    }

    func createViewController(for item: TabBarItem) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = AppColor.gray0

        let label = UILabel()
        label.text = item.title
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        return viewController
    }
}
