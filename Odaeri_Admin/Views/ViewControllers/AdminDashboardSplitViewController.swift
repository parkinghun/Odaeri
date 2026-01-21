//
//  AdminDashboardSplitViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
final class AdminDashboardSplitViewController: UISplitViewController {
    private let listContainerViewController = AdminOrdersListContainerViewController()
    private let detailContainerViewController = AdminDashboardDetailContainerViewController()
    private let listNavigationController: UINavigationController
    private let detailNavigationController: UINavigationController

    var inProgressSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        listContainerViewController.inProgressSortPublisher
    }

    var completedSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        listContainerViewController.completedSortPublisher
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity?, Never> {
        listContainerViewController.selectionPublisher
    }

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        let listUpdates = listContainerViewController.statusUpdatePublisher
        let detailUpdates = detailContainerViewController.statusUpdatePublisher
        return Publishers.Merge(listUpdates, detailUpdates).eraseToAnyPublisher()
    }

    init() {
        self.listNavigationController = UINavigationController(rootViewController: listContainerViewController)
        self.detailNavigationController = UINavigationController(rootViewController: detailContainerViewController)
        super.init(style: .doubleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        minimumPrimaryColumnWidth = Layout.minimumPrimaryColumnWidth
        maximumPrimaryColumnWidth = Layout.maximumPrimaryColumnWidth
        preferredPrimaryColumnWidthFraction = Layout.preferredPrimaryColumnWidthFraction
        setViewController(listNavigationController, for: .primary)
        setViewController(detailNavigationController, for: .secondary)
    }

    func show(tab: AdminDashboardTab) {
        listContainerViewController.show(tab: tab)
        detailContainerViewController.show(tab: tab)
    }

    func updateInProgressNew(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateInProgressNew(orders)
    }

    func updateInProgressActive(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateInProgressActive(orders)
    }

    func updateCompleted(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateCompleted(orders)
    }

    func updateOrder(_ order: OrderListItemEntity?) {
        detailContainerViewController.updateOrder(order)
    }

    func updateSalesSummary(_ summary: AdminSalesSummary) {
        detailContainerViewController.updateSalesSummary(summary)
    }

    func updateSalesCharts(_ charts: AdminSalesCharts) {
        detailContainerViewController.updateSalesCharts(charts)
    }

    func showError(message: String) {
        detailContainerViewController.showError(message: message)
    }
}

private enum Layout {
    static let minimumPrimaryColumnWidth: CGFloat = 320
    static let maximumPrimaryColumnWidth: CGFloat = 520
    static let preferredPrimaryColumnWidthFraction: CGFloat = 0.35
}
