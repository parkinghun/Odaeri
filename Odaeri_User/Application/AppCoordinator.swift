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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        setupNotificationObservers()
        checkAuthenticationStatus()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUnauthorizedAccess),
            name: .unauthorizedAccess,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshTokenExpired),
            name: .refreshTokenExpired,
            object: nil
        )
    }

    @objc private func handleUnauthorizedAccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.tokenManager.clearTokens()

            let alert = UIAlertController(
                title: "인증 오류",
                message: "로그인이 필요합니다. 다시 로그인해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                self.showAuthFlow()
            })

            self.navigationController.present(alert, animated: true)
        }
    }

    @objc private func handleRefreshTokenExpired() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.tokenManager.clearTokens()

            let alert = UIAlertController(
                title: "세션 만료",
                message: "로그인 세션이 만료되었습니다. 다시 로그인해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                self.showAuthFlow()
            })

            self.navigationController.present(alert, animated: true)
        }
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

        retryPendingPayments()
    }

    private func retryPendingPayments() {
        let pendingCount = PaymentService.shared.getPendingPaymentsCount()
        guard pendingCount > 0 else { return }

        print("앱 시작 시 pending payment \(pendingCount)개 재검증 시작")
        PaymentService.shared.retryPendingPayments()
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
