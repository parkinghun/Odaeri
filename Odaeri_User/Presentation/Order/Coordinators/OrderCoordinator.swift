//
//  OrderCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

protocol OrderCoordinatorDelegate: AnyObject {

}

final class OrderCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: HomeCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let orderViewModel = OrderViewModel()
        orderViewModel.coordinator = self
        let orderViewController = OrderViewController(viewModel: orderViewModel)
        navigationController.setViewControllers([orderViewController], animated: false)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(storeId: storeId)
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showReviewWrite(mode: ReviewWriteMode) {
        let viewModel = ReviewWriteViewModel(mode: mode)
        let viewController = ReviewWriteViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
