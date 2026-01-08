//
//  CommunityCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

protocol CommunityCoordinatorDelegate: AnyObject {
    
}

final class CommunityCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: CommunityCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let communityViewModel = CommunityViewModel()
        let communityViewController = CommunityViewController(viewModel: communityViewModel)
        communityViewController.coordinator = self
        navigationController.setViewControllers([communityViewController], animated: false)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(path: path)
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(storeId: storeId)
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
