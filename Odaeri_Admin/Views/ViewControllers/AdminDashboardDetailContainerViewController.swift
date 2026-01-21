//
//  AdminDashboardDetailContainerViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminDashboardDetailContainerViewController: UIViewController {
    private let orderDetailViewController = AdminOrderDetailViewController()
    private let salesViewController = AdminSalesViewController()
    private let statusUpdateSubject = PassthroughSubject<AdminOrderStatusUpdate, Never>()
    private var currentOrder: OrderListItemEntity?
    private var cancellables = Set<AnyCancellable>()

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        statusUpdateSubject.eraseToAnyPublisher()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        show(tab: .inProgress)
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0

        addChild(orderDetailViewController)
        addChild(salesViewController)

        view.addSubview(orderDetailViewController.view)
        view.addSubview(salesViewController.view)

        orderDetailViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        salesViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        orderDetailViewController.didMove(toParent: self)
        salesViewController.didMove(toParent: self)

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
    }

    private func bind() {
        orderDetailViewController.updateStatusPublisher
            .sink { [weak self] status in
                guard let self, let order = self.currentOrder else { return }
                self.statusUpdateSubject.send(AdminOrderStatusUpdate(order: order, nextStatus: status))
            }
            .store(in: &cancellables)
    }

    func show(tab: AdminDashboardTab) {
        orderDetailViewController.view.isHidden = tab == .sales
        salesViewController.view.isHidden = tab != .sales
        navigationItem.title = tab == .sales ? "매출 조회" : "주문 상세"
    }

    func updateOrder(_ order: OrderListItemEntity?) {
        currentOrder = order
        orderDetailViewController.configure(order: order)
    }

    func updateSalesSummary(_ summary: AdminSalesSummary) {
        salesViewController.updateSummary(summary)
    }

    func updateSalesCharts(_ charts: AdminSalesCharts) {
        salesViewController.updateCharts(charts)
    }

    func showError(message: String) {
        orderDetailViewController.showError(message: message)
    }
}
