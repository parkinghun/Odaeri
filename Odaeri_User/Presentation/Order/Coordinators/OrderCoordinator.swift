//
//  OrderCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

protocol OrderCoordinatorDelegate: AnyObject {

}

final class OrderCoordinator: Coordinator, ReviewWriteCoordinating {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: HomeCoordinatorDelegate?

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let orderViewModel = OrderViewModel(orderRepository: dependencies.orderRepository)
        orderViewModel.coordinator = self
        let orderViewController = OrderViewController(
            viewModel: orderViewModel,
            notificationCenter: dependencies.notificationCenter
        )
        navigationController.setViewControllers([orderViewController], animated: false)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(
            storeId: storeId,
            storeRepository: dependencies.storeRepository,
            orderRepository: dependencies.orderRepository,
            locationManager: dependencies.locationManager,
            routeManager: dependencies.routeManager
        )
        let viewController = ShopDetailViewController(
            viewModel: viewModel,
            notificationCenter: dependencies.notificationCenter
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    func showReviewWrite(mode: ReviewWriteMode) {
        let viewModel = ReviewWriteViewModel(
            mode: mode,
            repository: dependencies.storeReviewRepository
        )
        viewModel.coordinator = self
        let viewController = ReviewWriteViewController(
            viewModel: viewModel,
            notificationCenter: dependencies.notificationCenter
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    func popReviewWrite() {
        navigationController.popViewController(animated: true)
    }
}
