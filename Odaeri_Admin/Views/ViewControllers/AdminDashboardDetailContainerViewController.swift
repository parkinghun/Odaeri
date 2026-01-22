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
    private let storeManagementViewController: AdminStoreManagementDetailViewController
    private let salesViewController = AdminSalesViewController()
    private let statusUpdateSubject = PassthroughSubject<AdminOrderStatusUpdate, Never>()
    private var currentOrder: OrderListItemEntity?
    private var cancellables = Set<AnyCancellable>()

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        statusUpdateSubject.eraseToAnyPublisher()
    }

    var storeManagementSaveStorePublisher: AnyPublisher<AdminStoreFormData, Never> {
        storeManagementViewController.saveStorePublisher
    }

    var storeManagementSaveMenuPublisher: AnyPublisher<AdminMenuFormData, Never> {
        storeManagementViewController.saveMenuPublisher
    }

    init(storeManagementViewController: AdminStoreManagementDetailViewController = AdminStoreManagementDetailViewController()) {
        self.storeManagementViewController = storeManagementViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        addChild(storeManagementViewController)
        addChild(salesViewController)

        view.addSubview(orderDetailViewController.view)
        view.addSubview(storeManagementViewController.view)
        view.addSubview(salesViewController.view)

        orderDetailViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        storeManagementViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        salesViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        orderDetailViewController.didMove(toParent: self)
        storeManagementViewController.didMove(toParent: self)
        salesViewController.didMove(toParent: self)
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
        orderDetailViewController.view.isHidden = tab == .storeManagement || tab == .sales
        storeManagementViewController.view.isHidden = tab != .storeManagement
        salesViewController.view.isHidden = tab != .sales
        if tab == .storeManagement {
            navigationItem.title = "가게 관리"
        } else if tab == .sales {
            navigationItem.title = "매출 조회"
        } else {
            navigationItem.title = "주문 상세"
        }
    }

    func updateOrder(_ order: OrderListItemEntity?) {
        currentOrder = order
        orderDetailViewController.configure(order: order)
    }

    func updateStoreManagement(store: StoreEntity?, selectedItem: AdminStoreManagementItem) {
        storeManagementViewController.update(store: store, selectedItem: selectedItem)
    }

    func updateSalesOrders(_ orders: [OrderListItemEntity]) {
        salesViewController.updateOrders(orders)
    }

    func showError(message: String) {
        orderDetailViewController.showError(message: message)
    }
}
