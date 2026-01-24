//
//  AdminOrdersListContainerViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminOrdersListContainerViewController: UIViewController {
    private let inProgressViewController = AdminInProgressViewController()
    private let completedViewController = AdminCompletedViewController()
    private let orderLookupViewController = AdminOrderListViewController()
    private let storeManagementViewController: AdminStoreManagementListViewController
    private let salesListViewController = AdminSalesListPlaceholderViewController()

    var inProgressSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        inProgressViewController.sortPublisher
    }

    var completedSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        completedViewController.sortPublisher
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity?, Never> {
        let inProgress = inProgressViewController.selectionPublisher
        let completed = completedViewController.selectionPublisher
        let lookup = orderLookupViewController.selectionPublisher
            .map { Optional($0) }
            .eraseToAnyPublisher()
        return Publishers.Merge3(inProgress, completed, lookup)
            .eraseToAnyPublisher()
    }

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        inProgressViewController.statusUpdatePublisher
    }

    init(storeManagementViewController: AdminStoreManagementListViewController = AdminStoreManagementListViewController()) {
        self.storeManagementViewController = storeManagementViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        show(tab: .inProgress)
    }

    var storeManagementViewDidLoadPublisher: AnyPublisher<Void, Never> {
        storeManagementViewController.viewDidLoadPublisher
    }

    var storeManagementSelectionPublisher: AnyPublisher<AdminStoreManagementItem, Never> {
        storeManagementViewController.selectionPublisher
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray15

        addChild(inProgressViewController)
        addChild(completedViewController)
        addChild(orderLookupViewController)
        addChild(storeManagementViewController)
        addChild(salesListViewController)

        view.addSubview(inProgressViewController.view)
        view.addSubview(completedViewController.view)
        view.addSubview(orderLookupViewController.view)
        view.addSubview(storeManagementViewController.view)
        view.addSubview(salesListViewController.view)

        [
            inProgressViewController.view,
            completedViewController.view,
            orderLookupViewController.view,
            storeManagementViewController.view,
            salesListViewController.view
        ].forEach { childView in
            childView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        inProgressViewController.didMove(toParent: self)
        completedViewController.didMove(toParent: self)
        orderLookupViewController.didMove(toParent: self)
        storeManagementViewController.didMove(toParent: self)
        salesListViewController.didMove(toParent: self)
    }

    func show(tab: AdminDashboardTab) {
        inProgressViewController.view.isHidden = tab != .inProgress
        completedViewController.view.isHidden = tab != .completed
        orderLookupViewController.view.isHidden = tab != .orderLookup
        salesListViewController.view.isHidden = tab != .sales
        storeManagementViewController.view.isHidden = tab != .storeManagement
        navigationItem.title = title(for: tab)
    }

    func updateInProgressNew(_ orders: [OrderListItemEntity]) {
        inProgressViewController.updateNewOrders(orders)
    }

    func updateInProgressActive(_ orders: [OrderListItemEntity]) {
        inProgressViewController.updateActiveOrders(orders)
    }

    func updateCompleted(_ orders: [OrderListItemEntity]) {
        completedViewController.updateOrders(orders)
    }

    func updateOrderLookup(_ orders: [OrderListItemEntity]) {
        orderLookupViewController.updateOrders(orders)
    }

    func updateStoreManagementStore(_ store: StoreEntity?) {
        storeManagementViewController.updateStore(store)
    }

    func updateStoreManagementSelection(_ item: AdminStoreManagementItem) {
        storeManagementViewController.updateSelection(item)
    }

    private func title(for tab: AdminDashboardTab) -> String {
        switch tab {
        case .inProgress:
            return "주문 목록"
        case .completed:
            return "완료 목록"
        case .orderLookup:
            return "주문 조회"
        case .sales:
            return "매출 조회"
        case .storeManagement:
            return "가게 관리"
        }
    }
}

private final class AdminSalesListPlaceholderViewController: UIViewController {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "매출 분석은 오른쪽 상세 화면에서 확인할 수 있습니다."
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray15
        view.addSubview(label)
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.xLarge)
        }
    }
}
