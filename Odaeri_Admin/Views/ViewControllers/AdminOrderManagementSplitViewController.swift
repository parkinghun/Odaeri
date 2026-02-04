//
//  AdminOrderManagementSplitViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit

final class AdminOrderManagementSplitViewController: UISplitViewController {
    private let listViewController = IntegratedOrderListViewController()
    private let detailViewController = AdminOrderDetailViewController()

    private var sampleOrders: [OrderListItemEntity] = []

    init() {
        super.init(style: .doubleColumn)
        setupControllers()
        loadSampleOrders()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupControllers() {
        listViewController.delegate = self
        setViewController(listViewController, for: .primary)
        setViewController(detailViewController, for: .secondary)
        preferredDisplayMode = .oneBesideSecondary
        presentsWithGesture = false
    }

    private func loadSampleOrders() {
        sampleOrders = AdminOrderMockFactory.makeOrders()
        listViewController.updateOrders(sampleOrders)
    }
}

extension AdminOrderManagementSplitViewController: IntegratedOrderListViewControllerDelegate {
    func orderListViewController(_ controller: IntegratedOrderListViewController, didSelect order: OrderListItemEntity) {
        detailViewController.configure(order: order)
    }
}
