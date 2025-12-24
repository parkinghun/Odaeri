//
//  HomeCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSelectStore(_ coordinator: HomeCoordinator, storeId: String)
}

final class HomeCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: HomeCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let homeViewModel = HomeViewModel()
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        homeViewController.coordinator = self
        navigationController.setViewControllers([homeViewController], animated: false)
    }

    func showStoreDetail(storeId: String) {
        delegate?.homeCoordinatorDidSelectStore(self, storeId: storeId)
    }
}
