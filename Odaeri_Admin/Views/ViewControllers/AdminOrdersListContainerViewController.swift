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
    private let emptyView = AdminEmptyListView()

    var inProgressSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        inProgressViewController.sortPublisher
    }

    var completedSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        completedViewController.sortPublisher
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity?, Never> {
        Publishers.Merge(inProgressViewController.selectionPublisher, completedViewController.selectionPublisher)
            .eraseToAnyPublisher()
    }

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        inProgressViewController.statusUpdatePublisher
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        show(tab: .inProgress)
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray15

        addChild(inProgressViewController)
        addChild(completedViewController)
        addChild(emptyView)

        view.addSubview(inProgressViewController.view)
        view.addSubview(completedViewController.view)
        view.addSubview(emptyView.view)

        [inProgressViewController.view, completedViewController.view, emptyView.view].forEach { childView in
            childView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        inProgressViewController.didMove(toParent: self)
        completedViewController.didMove(toParent: self)
        emptyView.didMove(toParent: self)
    }

    func show(tab: AdminDashboardTab) {
        inProgressViewController.view.isHidden = tab != .inProgress
        completedViewController.view.isHidden = tab != .completed
        emptyView.view.isHidden = tab != .sales
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

    private func title(for tab: AdminDashboardTab) -> String {
        switch tab {
        case .inProgress:
            return "주문 목록"
        case .completed:
            return "완료 목록"
        case .sales:
            return "매출"
        }
    }
}

private final class AdminEmptyListView: UIViewController {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "매출 조회는 상세 화면에서 확인할 수 있습니다."
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
