//
//  ProfileCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/22/25.
//

import UIKit

protocol ProfileCoordinatorDelegate: AnyObject {
    func profileCoordinatorDidFinishLogout(_ coordinator: ProfileCoordinator)
}

final class ProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: ProfileCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let profileViewModel = ProfileViewModel()
        profileViewModel.coordinator = self
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        navigationController.setViewControllers([profileViewController], animated: false)
    }

    func didFinishLogout() {
        delegate?.profileCoordinatorDidFinishLogout(self)
    }
}
