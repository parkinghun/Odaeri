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
        let viewControllers = TabBarItem.allCases.map { createTab(for: $0) }

        tabBarController.viewControllers = viewControllers
        navigationController.setViewControllers([tabBarController], animated: false)
        navigationController.isNavigationBarHidden = true
    }
}

// MARK: - Tab Creation
private extension MainCoordinator {
    func createTab(for item: TabBarItem) -> UINavigationController {
        let tabNavigationController = UINavigationController()
        tabNavigationController.navigationBar.isHidden = true

        switch item {
        case .home:
            let homeCoordinator = HomeCoordinator(navigationController: tabNavigationController)
            homeCoordinator.delegate = self
            addChild(homeCoordinator)
            homeCoordinator.start()

        case .profile:
            let profileCoordinator = ProfileCoordinator(navigationController: tabNavigationController)
            profileCoordinator.delegate = self
            addChild(profileCoordinator)
            profileCoordinator.start()

        case .order:
            let orderCoordinator = OrderCoordinator(navigationController: tabNavigationController)
            orderCoordinator.delegate = self
            addChild(orderCoordinator)
            orderCoordinator.start()
            
        default:
            // 기본 화면 (구현되지 않은 탭)
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

            tabNavigationController.setViewControllers([viewController], animated: false)
        }

        return tabNavigationController
    }
}

// MARK: - HomeCoordinator
extension MainCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidSelectStore(_ coordinator: HomeCoordinator, storeId: String) {
        // TODO: 상점 상세 화면으로 이동
    }
}

// MARK: - ProfileCoordinator
extension MainCoordinator: ProfileCoordinatorDelegate {
    func profileCoordinatorDidFinishLogout(_ coordinator: ProfileCoordinator) {
        removeChild(coordinator)
        delegate?.mainCoordinatorDidLogout(self)
    }
}
