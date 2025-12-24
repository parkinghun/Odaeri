//
//  AppCoordinator.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let tokenManager = TokenManager.shared

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.isNavigationBarHidden = true
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        if tokenManager.isLoggedIn {
            showMainFlow()
        } else {
            showAuthFlow()
        }
    }

    func showMainFlow() {
        childCoordinators.removeAll()

        let mainCoordinator = MainCoordinator(navigationController: navigationController)
        mainCoordinator.delegate = self
        addChild(mainCoordinator)
        mainCoordinator.start()
    }

    func showAuthFlow() {
        childCoordinators.removeAll()

        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.delegate = self
        addChild(authCoordinator)
        authCoordinator.start()
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidFinishLogin(_ coordinator: AuthCoordinator) {
        removeChild(coordinator)
        showMainFlow()
    }
}

// MARK: - MainCoordinatorDelegate

extension AppCoordinator: MainCoordinatorDelegate {
    func mainCoordinatorDidLogout(_ coordinator: MainCoordinator) {
        removeChild(coordinator)
        showAuthFlow()
    }
}
