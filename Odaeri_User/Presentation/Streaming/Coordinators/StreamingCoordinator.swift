//
//  StreamingCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit

protocol StreamingCoordinatorDelegate: AnyObject {
}

final class StreamingCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: StreamingCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = StreamingViewModel()
        viewModel.coordinator = self
        let viewController = StreamingViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
