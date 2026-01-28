//
//  AppCoordinator.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit
import Combine

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let dependencies: UserDependencyContainer
    private var cancellables = Set<AnyCancellable>()
    private var mainCoordinator: MainCoordinator?
    private var pendingChatRoomId: String?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.isNavigationBarHidden = true
        self.dependencies = UserDependencyContainer()
    }

    deinit {
        dependencies.notificationCenter.removeObserver(self)
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        setupNotificationObservers()
        checkAuthenticationStatus()
    }

    private func setupNotificationObservers() {
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(handleUnauthorizedAccess),
            name: .unauthorizedAccess,
            object: nil
        )

        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(handleRefreshTokenExpired),
            name: .refreshTokenExpired,
            object: nil
        )

        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(handleSessionInvalidated),
            name: .sessionInvalidated,
            object: nil
        )
    }

    @objc private func handleUnauthorizedAccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.dependencies.tokenManager.clearTokens()

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

            self.dependencies.tokenManager.clearTokens()
            self.navigationController.dismiss(animated: false)
            self.showAuthFlow()
        }
    }

    @objc private func handleSessionInvalidated() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let alert = UIAlertController(
                title: "세션 종료",
                message: "다른 기기에서 로그인되어 세션이 종료되었습니다.\n다시 로그인해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.navigationController.dismiss(animated: false)
                self?.showAuthFlow()
            })

            if let presented = self.navigationController.presentedViewController {
                presented.present(alert, animated: true)
            } else {
                self.navigationController.present(alert, animated: true)
            }
        }
    }

    private func checkAuthenticationStatus() {
        if dependencies.tokenManager.isLoggedIn {
            restoreCurrentUserIfNeeded()
        } else {
            showAuthFlow()
        }
    }

    private func restoreCurrentUserIfNeeded() {
        if dependencies.userManager.currentUser != nil {
            showMainFlow()
            return
        }

        dependencies.userRepository.getMyProfile()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.showMainFlow()
                    }
                },
                receiveValue: { [weak self] user in
                    self?.dependencies.userManager.saveUser(user)
                    self?.showMainFlow()
                }
            )
            .store(in: &cancellables)
    }

    func showMainFlow() {
        childCoordinators.removeAll()

        let mainCoordinator = MainCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        mainCoordinator.delegate = self
        self.mainCoordinator = mainCoordinator
        addChild(mainCoordinator)
        mainCoordinator.start()

        retryPendingPayments()

        if let roomId = pendingChatRoomId {
            pendingChatRoomId = nil
            mainCoordinator.showChatRoom(roomId: roomId)
        }
    }

    private func retryPendingPayments() {
        let pendingCount = dependencies.paymentService.getPendingPaymentsCount()
        guard pendingCount > 0 else { return }

        print("앱 시작 시 pending payment \(pendingCount)개 재검증 시작")
        dependencies.paymentService.retryPendingPayments()
    }

    func showAuthFlow() {
        childCoordinators.removeAll()
        mainCoordinator = nil

        let authCoordinator = AuthCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        authCoordinator.delegate = self
        addChild(authCoordinator)
        authCoordinator.start()
    }

    func handleChatDeepLink(roomId: String) {
        if dependencies.tokenManager.isLoggedIn {
            if dependencies.userManager.currentUser != nil {
                showMainFlow()
                mainCoordinator?.showChatRoom(roomId: roomId)
                return
            }

            pendingChatRoomId = roomId
            restoreCurrentUserIfNeeded()
            return
        }

        pendingChatRoomId = roomId
        showAuthFlow()
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
