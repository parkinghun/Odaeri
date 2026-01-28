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
    private var communityCoordinator: CommunityCoordinator?
    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
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
        configureNavigationBarAppearance(for: tabNavigationController)

        switch item {
        case .home:
            let homeCoordinator = HomeCoordinator(
                navigationController: tabNavigationController,
                dependencies: dependencies
            )
            homeCoordinator.delegate = self
            addChild(homeCoordinator)
            homeCoordinator.start()

        case .order:
            let orderCoordinator = OrderCoordinator(
                navigationController: tabNavigationController,
                dependencies: dependencies
            )
            orderCoordinator.delegate = self
            addChild(orderCoordinator)
            orderCoordinator.start()
            
        case .streaming:
            let streamingCoordinator = StreamingCoordinator(
                navigationController: tabNavigationController,
                dependencies: dependencies
            )
            addChild(streamingCoordinator)
            streamingCoordinator.start()
            
        case .community:
            let communityCoordinator = CommunityCoordinator(
                navigationController: tabNavigationController,
                dependencies: dependencies
            )
            communityCoordinator.delegate = self
            addChild(communityCoordinator)
            communityCoordinator.start()
            self.communityCoordinator = communityCoordinator
            
        case .profile:
            let profileCoordinator = ProfileCoordinator(
                navigationController: tabNavigationController,
                dependencies: dependencies
            )
            profileCoordinator.delegate = self
            addChild(profileCoordinator)
            profileCoordinator.start()
            
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

    func configureNavigationBarAppearance(for navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = AppColor.gray100
    }
}

// MARK: - Deep Link
extension MainCoordinator {
    func showChatRoom(roomId: String) {
        let targetIndex = TabBarItem.allCases.firstIndex(of: .community) ?? 0
        tabBarController.selectedIndex = targetIndex
        communityCoordinator?.showChatRoom(roomId: roomId, title: nil)
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

// MARK: - OrderCoordinator
extension MainCoordinator: OrderCoordinatorDelegate {

}

// MARK: - CommunityCoordinator
extension MainCoordinator: CommunityCoordinatorDelegate {
    func communityCoordinatorDidCreatePost(_ coordinator: CommunityCoordinator) {
        guard let communityNavController = communityCoordinator?.navigationController else { return }

        if let communityVC = communityNavController.viewControllers.first as? CommunityViewController {
            communityVC.refresh()
        }
    }
}
