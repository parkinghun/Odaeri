//
//  AdminOrderListViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class AdminOrderListViewController: UIViewController {
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let selectionSubject = PassthroughSubject<OrderListItemEntity, Never>()
    private var orders: [OrderListItemEntity] = []
    private var selectedOrderId: String?

    var viewDidLoadPublisher: AnyPublisher<Void, Never> {
        viewDidLoadSubject.eraseToAnyPublisher()
    }

    var refreshPublisher: AnyPublisher<Void, Never> {
        refreshSubject.eraseToAnyPublisher()
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문 목록"
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 84
        tableView.estimatedRowHeight = 84
        tableView.register(AdminOrderListCell.self, forCellReuseIdentifier: AdminOrderListCell.reuseIdentifier)
        return tableView
    }()

    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewDidLoadSubject.send(())
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        navigationItem.titleView = titleLabel

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    func updateOrders(_ orders: [OrderListItemEntity]) {
        self.orders = orders
        tableView.reloadData()
    }

    func updateSelectedOrderId(_ orderId: String?) {
        selectedOrderId = orderId
        tableView.reloadData()
    }

    func updateOrder(_ updated: OrderListItemEntity) {
        guard let index = orders.firstIndex(where: { $0.orderId == updated.orderId }) else { return }
        orders[index] = updated
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    func setLoading(_ isLoading: Bool) {
        if !isLoading {
            refreshControl.endRefreshing()
        }
    }

    @objc private func handleRefresh() {
        refreshSubject.send(())
    }
}

extension AdminOrderListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminOrderListCell.reuseIdentifier,
            for: indexPath
        ) as! AdminOrderListCell
        let order = orders[indexPath.row]
        let isSelected = order.orderId == selectedOrderId
        cell.configure(order: order, isSelected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = orders[indexPath.row]
        selectedOrderId = order.orderId
        selectionSubject.send(order)
        tableView.reloadData()
    }
}

private final class AdminOrderListCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderListCell"

    private let containerView = UIView()
    private let orderCodeLabel = UILabel()
    private let storeNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = AppColor.gray0

        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColor.gray30.cgColor
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.medium)
        }

        orderCodeLabel.font = AppFont.body1Bold
        orderCodeLabel.textColor = AppColor.gray90
        storeNameLabel.font = AppFont.body2
        storeNameLabel.textColor = AppColor.gray75
        timeLabel.font = AppFont.caption1
        timeLabel.textColor = AppColor.gray60
        statusLabel.font = AppFont.caption1
        statusLabel.textColor = AppColor.gray0
        statusLabel.backgroundColor = AppColor.gray60
        statusLabel.layer.cornerRadius = 10
        statusLabel.clipsToBounds = true
        statusLabel.textAlignment = .center

        let topStack = UIStackView(arrangedSubviews: [orderCodeLabel, statusLabel])
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [topStack, storeNameLabel, timeLabel])
        stack.axis = .vertical
        stack.spacing = 6
        containerView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        statusLabel.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(70)
            $0.height.equalTo(20)
        }
    }

    func configure(order: OrderListItemEntity, isSelected: Bool) {
        orderCodeLabel.text = "주문번호 \(order.orderCode)"
        storeNameLabel.text = order.store.name
        timeLabel.text = order.createdAt?.toRelativeTime ?? "방금 전"
        statusLabel.text = order.currentOrderStatus.description
        statusLabel.backgroundColor = statusColor(for: order.currentOrderStatus)
        containerView.layer.borderColor = isSelected ? AppColor.deepSprout.cgColor : AppColor.gray30.cgColor
        containerView.backgroundColor = isSelected ? AppColor.brightSprout : AppColor.gray0
    }

    private func statusColor(for status: OrderStatusEntity) -> UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.brightForsythia
        case .approved, .inProgress:
            return AppColor.deepSprout
        case .readyForPickup:
            return AppColor.blackSprout
        case .pickedUp:
            return AppColor.gray60
        }
    }
}
