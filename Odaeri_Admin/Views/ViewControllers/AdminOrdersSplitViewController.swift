//
//  AdminOrdersSplitViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine

final class AdminOrdersSplitViewController: UISplitViewController {
    private let viewModel: AdminOrdersViewModel
    private var cancellables = Set<AnyCancellable>()

    private let listViewController: AdminOrderListViewController
    private let detailViewController: AdminOrderDetailViewController
    private let listNavigationController: UINavigationController
    private let detailNavigationController: UINavigationController

    init(viewModel: AdminOrdersViewModel = AdminOrdersViewModel()) {
        self.viewModel = viewModel
        self.listViewController = AdminOrderListViewController()
        self.detailViewController = AdminOrderDetailViewController()
        self.listNavigationController = UINavigationController(rootViewController: listViewController)
        self.detailNavigationController = UINavigationController(rootViewController: detailViewController)
        super.init(style: .doubleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        minimumPrimaryColumnWidth = 250
        delegate = self
        setViewController(listNavigationController, for: .primary)
        setViewController(detailNavigationController, for: .secondary)
        bind()
        updateDetailSafeArea(for: displayMode)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDetailSafeArea(for: displayMode)
    }

    private func bind() {
        let input = AdminOrdersViewModel.Input(
            viewDidLoad: listViewController.viewDidLoadPublisher,
            refresh: listViewController.refreshPublisher,
            selectOrder: listViewController.selectionPublisher,
            updateStatus: detailViewController.updateStatusPublisher
        )
        let output = viewModel.transform(input: input)

        output.orders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.listViewController.updateOrders(orders)
            }
            .store(in: &cancellables)

        output.selectedOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.detailViewController.configure(order: order)
                self?.listViewController.updateSelectedOrderId(order?.orderId)
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.listViewController.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.detailViewController.showError(message: message)
            }
            .store(in: &cancellables)

        output.statusUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                self?.listViewController.updateOrder(updated)
            }
            .store(in: &cancellables)
    }
}

extension AdminOrdersSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        updateDetailSafeArea(for: displayMode)
    }
}

private extension AdminOrdersSplitViewController {
    func updateDetailSafeArea(for displayMode: UISplitViewController.DisplayMode) {
        let shouldInset = displayMode == .oneOverSecondary
        let inset = shouldInset ? primaryColumnWidth : 0
        detailNavigationController.additionalSafeAreaInsets.left = inset
    }
}
