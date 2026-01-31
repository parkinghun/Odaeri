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

    private var sampleOrders: [Order] = []

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
        let menu = Menu(name: "SaeSsac Burger", price: 100, quantity: 2, imageUrl: nil)
        sampleOrders = [
            Order(orderCode: "A-101", totalPrice: 200, status: .pending, orderTime: Date(), storeName: "SaeSsac Cafe", menus: [menu]),
            Order(orderCode: "A-102", totalPrice: 320, status: .cooking, orderTime: Date(), storeName: "SaeSsac Cafe", menus: [menu]),
            Order(orderCode: "A-103", totalPrice: 150, status: .completed, orderTime: Date(), storeName: "SaeSsac Cafe", menus: [menu])
        ]
        listViewController.updateOrders(sampleOrders)
    }
}

extension AdminOrderManagementSplitViewController: IntegratedOrderListViewControllerDelegate {
    func orderListViewController(_ controller: IntegratedOrderListViewController, didSelect order: Order) {
        detailViewController.configure(order: order)
    }
}
