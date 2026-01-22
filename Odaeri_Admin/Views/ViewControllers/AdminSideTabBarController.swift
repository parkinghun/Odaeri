//
//  AdminSideTabBarController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminSideTabBarController: UIViewController {
    private let sideTabBar = AdminSideTabBar()
    private let dashboardController = AdminDashboardSplitViewController()
    private let viewModel: AdminDashboardViewModel
    private let selectedTabSubject = CurrentValueSubject<AdminDashboardTab, Never>(.inProgress)
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AdminDashboardViewModel = AdminDashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.adminDark

        addChild(sideTabBar)
        addChild(dashboardController)
        view.addSubview(sideTabBar.view)
        view.addSubview(dashboardController.view)
        sideTabBar.didMove(toParent: self)
        dashboardController.didMove(toParent: self)

        sideTabBar.view.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.width.equalTo(Layout.tabBarWidth)
        }

        dashboardController.view.snp.makeConstraints {
            $0.leading.equalTo(sideTabBar.view.snp.trailing)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.trailing.equalToSuperview()
        }
    }

    private func bind() {
        sideTabBar.selectionPublisher
            .sink { [weak self] tab in
                self?.selectedTabSubject.send(tab)
            }
            .store(in: &cancellables)

        sideTabBar.settingsPublisher
            .sink { [weak self] in
                self?.presentSettings()
            }
            .store(in: &cancellables)

        let input = AdminDashboardViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            refresh: Empty(completeImmediately: false).eraseToAnyPublisher(),
            selectTab: selectedTabSubject.eraseToAnyPublisher(),
            inProgressSort: dashboardController.inProgressSortPublisher,
            completedSort: dashboardController.completedSortPublisher,
            selectOrder: dashboardController.selectionPublisher,
            updateStatus: dashboardController.statusUpdatePublisher
        )
        let output = viewModel.transform(input: input)

        output.sideTabBarItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.sideTabBar.updateItems(items)
            }
            .store(in: &cancellables)

        output.selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                self?.sideTabBar.updateSelection(tab)
                self?.dashboardController.show(tab: tab)
            }
            .store(in: &cancellables)

        output.inProgressNew
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateInProgressNew(orders)
            }
            .store(in: &cancellables)

        output.inProgressActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateInProgressActive(orders)
            }
            .store(in: &cancellables)

        output.completedOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateCompleted(orders)
            }
            .store(in: &cancellables)

        output.orderLookupOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateOrderLookup(orders)
            }
            .store(in: &cancellables)

        output.selectedOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.dashboardController.updateOrder(order)
            }
            .store(in: &cancellables)

        output.salesOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateSalesOrders(orders)
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.dashboardController.showError(message: message)
            }
            .store(in: &cancellables)
    }

    private func presentSettings() {
        let settingsViewController = AdminSettingsViewController()
        settingsViewController.onStoreIdUpdated = { [weak self] in
            self?.dashboardController.reloadStoreManagement()
        }
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
}

private enum Layout {
    static let tabBarWidth: CGFloat = 90
}
