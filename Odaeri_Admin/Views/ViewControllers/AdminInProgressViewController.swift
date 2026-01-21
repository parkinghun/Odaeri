//
//  AdminInProgressViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminInProgressViewController: UIViewController {
    private let sortSubject = CurrentValueSubject<AdminSortOrder, Never>(.latest)
    private let statusUpdateSubject = PassthroughSubject<AdminOrderStatusUpdate, Never>()
    private let selectionSubject = PassthroughSubject<OrderListItemEntity?, Never>()
    private var newOrders: [OrderListItemEntity] = []
    private var activeOrders: [OrderListItemEntity] = []

    var sortPublisher: AnyPublisher<AdminSortOrder, Never> {
        sortSubject.eraseToAnyPublisher()
    }

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        statusUpdateSubject.eraseToAnyPublisher()
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity?, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColor.gray15
        tableView.register(AdminOrderCardCell.self, forCellReuseIdentifier: AdminOrderCardCell.reuseIdentifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray15
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    func updateNewOrders(_ orders: [OrderListItemEntity]) {
        newOrders = orders
        tableView.reloadData()
    }

    func updateActiveOrders(_ orders: [OrderListItemEntity]) {
        activeOrders = orders
        tableView.reloadData()
    }
}

extension AdminInProgressViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? newOrders.count : activeOrders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminOrderCardCell.reuseIdentifier,
            for: indexPath
        ) as! AdminOrderCardCell

        let order = indexPath.section == 0 ? newOrders[indexPath.row] : activeOrders[indexPath.row]
        let highlight = indexPath.section == 0
        let showsTimer = indexPath.section == 1
        let actionTitle = actionTitle(for: order, section: indexPath.section)
        let nextStatus = nextStatus(for: order, section: indexPath.section)

        cell.configure(
            order: order,
            highlight: highlight,
            showsTimer: showsTimer,
            actionTitle: actionTitle
        ) { [weak self] in
            let update = AdminOrderStatusUpdate(order: order, nextStatus: nextStatus)
            self?.statusUpdateSubject.send(update)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = indexPath.section == 0 ? newOrders[indexPath.row] : activeOrders[indexPath.row]
        selectionSubject.send(order)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return AdminSectionHeaderView(title: "신규 주문", backgroundColor: AppColor.brightForsythia.withAlphaComponent(0.12))
        }
        let header = AdminInProgressSortHeaderView()
        header.configure(selected: sortSubject.value)
        header.onSortChanged = { [weak self] order in
            self?.sortSubject.send(order)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Layout.headerHeight
    }
}

private final class AdminSectionHeaderView: UIView {
    private let titleLabel = UILabel()

    init(title: String, backgroundColor: UIColor = .clear) {
        super.init(frame: .zero)
        setupUI(title: title, backgroundColor: backgroundColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90
        titleLabel.text = title
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.xLarge)
            $0.centerY.equalToSuperview()
        }
    }
}

private final class AdminInProgressSortHeaderView: UIView {
    var onSortChanged: ((AdminSortOrder) -> Void)?
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: AdminSortOrder.allCases.map { $0.title })

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90
        titleLabel.text = "진행 주문"

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(handleSortChange), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [titleLabel, segmentedControl])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = AppSpacing.large
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.xLarge)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(selected: AdminSortOrder) {
        segmentedControl.selectedSegmentIndex = selected.rawValue
    }

    @objc private func handleSortChange() {
        guard let order = AdminSortOrder(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        onSortChanged?(order)
    }
}

private extension AdminInProgressViewController {
    func actionTitle(for order: OrderListItemEntity, section: Int) -> String {
        if section == 0 {
            return "접수하기"
        }
        return order.currentOrderStatus == .readyForPickup ? "픽업 완료" : "조리 완료"
    }

    func nextStatus(for order: OrderListItemEntity, section: Int) -> OrderStatusEntity {
        if section == 0 {
            return .approved
        }
        return order.currentOrderStatus == .readyForPickup ? .pickedUp : .readyForPickup
    }
}

private enum Layout {
    static let rowHeight: CGFloat = 140
    static let headerHeight: CGFloat = 52
}
