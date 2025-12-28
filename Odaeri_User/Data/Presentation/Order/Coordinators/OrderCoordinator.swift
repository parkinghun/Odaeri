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
        let orderViewController = OrderViewController(viewModel: orderViewModel)
        orderViewController.coordinator = self
        navigationController.setViewControllers([orderViewController], animated: false)
    }
}

