//
//  AdminSideTabBarController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import SnapKit

final class AdminSideTabBarController: UIViewController {
    private let sidebarView = AdminSidebarView()
    private let contentContainer = UIView()

    private let orderManagementController = MainContainerViewController()
    private let salesController = AdminSalesViewController()
    private let storeManagementController = AdminStoreManagementContainerViewController()

    private var selectedItem: AdminSidebarItem = .orderManagement

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        setupNotificationObservers()
        showContent(for: selectedItem)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = AppColor.adminDark

        view.addSubview(sidebarView)
        view.addSubview(contentContainer)

        sidebarView.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.width.equalTo(Layout.sidebarWidth)
        }

        contentContainer.snp.makeConstraints {
            $0.leading.equalTo(sidebarView.snp.trailing)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.trailing.equalToSuperview()
        }
    }

    private func bind() {
        sidebarView.onSelectItem = { [weak self] item in
            guard let self else { return }
            if item == .settings {
                self.presentSettings()
                return
            }
            self.selectedItem = item
            self.showContent(for: item)
        }
    }

    private func showContent(for item: AdminSidebarItem) {
        let controller: UIViewController
        switch item {
        case .orderManagement:
            controller = orderManagementController
        case .sales:
            controller = salesController
        case .storeManagement:
            controller = storeManagementController
        case .settings:
            return
        }

        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        addChild(controller)
        contentContainer.addSubview(controller.view)
        controller.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        controller.didMove(toParent: self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionInvalidated),
            name: .sessionInvalidated,
            object: nil
        )
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
                self?.logout()
            })

            self.present(alert, animated: true)
        }
    }

    private func logout() {
        TokenManager.shared.clearTokens()

        let loginViewModel = AdminLoginViewModel()
        let loginViewController = AdminLoginViewController(viewModel: loginViewModel)
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.navigationBar.isHidden = true

        loginViewController.onLoginSuccess = { [weak self] in
            self?.view.window?.rootViewController = AdminSideTabBarController()
            self?.view.window?.makeKeyAndVisible()
        }

        view.window?.rootViewController = navigationController
        view.window?.makeKeyAndVisible()
    }

    private func presentSettings() {
        let settingsViewController = AdminSettingsViewController()
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
}

private enum Layout {
    static let sidebarWidth: CGFloat = 220
}
