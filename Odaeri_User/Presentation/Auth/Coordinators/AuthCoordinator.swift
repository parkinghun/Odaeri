//
//  AuthCoordinator.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit

protocol AuthCoordinatorDelegate: AnyObject {
    func authCoordinatorDidFinishLogin(_ coordinator: AuthCoordinator)
}

final class AuthCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: AuthCoordinatorDelegate?

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        showLogin()
    }

    private func showLogin() {
        let viewModel = LoginViewModel(
            repository: dependencies.userRepository,
            tokenManager: dependencies.tokenManager,
            userManager: dependencies.userManager
        )
        viewModel.coordinator = self
        let viewController = LoginViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func showSignUp() {
        let viewModel = SignUpViewModel(
            repository: dependencies.userRepository,
            tokenManager: dependencies.tokenManager,
            userManager: dependencies.userManager
        )
        viewModel.coordinator = self
        let viewController = SignUpViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func didFinishLogin() {
        delegate?.authCoordinatorDidFinishLogin(self)
    }
}
