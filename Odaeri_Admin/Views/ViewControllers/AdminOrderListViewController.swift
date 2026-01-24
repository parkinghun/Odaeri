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
    private var allOrders: [OrderListItemEntity] = []
    private var filteredOrders: [OrderListItemEntity] = []
    private var selectedOrderId: String?
    private var currentFilter: OrderLookupFilter = .all
    private var currentSort: AdminSortOrder = .latest
    private var searchText = ""

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
        tableView.rowHeight = 108
        tableView.estimatedRowHeight = 108
        tableView.register(AdminOrderListCell.self, forCellReuseIdentifier: AdminOrderListCell.reuseIdentifier)
        return tableView
    }()

    private let headerContainerView = UIView()
    private let searchBar = UISearchBar()
    private let filterSegmented = UISegmentedControl(items: OrderLookupFilter.allCases.map { $0.title })
    private let sortSegmented = UISegmentedControl(items: AdminSortOrder.allCases.map { $0.title })
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
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
        tableView.tableHeaderView = headerContainerView
        tableView.backgroundView = emptyLabel
        setupHeaderView()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    func updateOrders(_ orders: [OrderListItemEntity]) {
        allOrders = orders
        applyFilters()
    }

    func updateSelectedOrderId(_ orderId: String?) {
        selectedOrderId = orderId
        tableView.reloadData()
    }

    func updateOrder(_ updated: OrderListItemEntity) {
        guard let index = allOrders.firstIndex(where: { $0.orderId == updated.orderId }) else { return }
        allOrders[index] = updated
        applyFilters()
    }

    func setLoading(_ isLoading: Bool) {
        if !isLoading {
            refreshControl.endRefreshing()
        }
    }

    @objc private func handleRefresh() {
        refreshSubject.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerContainerView.systemLayoutSizeFitting(targetSize).height
        if headerContainerView.frame.height != height {
            headerContainerView.frame.size.height = height
            tableView.tableHeaderView = headerContainerView
        }
    }

    private func setupHeaderView() {
        headerContainerView.backgroundColor = AppColor.gray0

        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "주문번호 또는 매장명 검색"
        searchBar.delegate = self

        filterSegmented.selectedSegmentIndex = OrderLookupFilter.allCases.firstIndex(of: currentFilter) ?? 0
        filterSegmented.addTarget(self, action: #selector(handleFilterChanged), for: .valueChanged)

        sortSegmented.selectedSegmentIndex = AdminSortOrder.allCases.firstIndex(of: currentSort) ?? 0
        sortSegmented.addTarget(self, action: #selector(handleSortChanged), for: .valueChanged)

        let controlStack = UIStackView(arrangedSubviews: [filterSegmented, sortSegmented])
        controlStack.axis = .vertical
        controlStack.spacing = Layout.headerSpacing

        let stack = UIStackView(arrangedSubviews: [searchBar, controlStack])
        stack.axis = .vertical
        stack.spacing = Layout.headerSpacing

        headerContainerView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.headerInsets)
        }
    }

    @objc private func handleFilterChanged() {
        let index = filterSegmented.selectedSegmentIndex
        currentFilter = OrderLookupFilter.allCases[safe: index] ?? .all
        applyFilters()
    }

    @objc private func handleSortChanged() {
        let index = sortSegmented.selectedSegmentIndex
        currentSort = AdminSortOrder.allCases[safe: index] ?? .latest
        applyFilters()
    }

    private func applyFilters() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = allOrders.filter { order in
            guard currentFilter.matches(order: order) else { return false }
            if trimmedQuery.isEmpty { return true }
            let matchesCode = order.orderCode.lowercased().contains(trimmedQuery)
            let matchesStore = order.store.name.lowercased().contains(trimmedQuery)
            return matchesCode || matchesStore
        }

        result = result.sorted { left, right in
            let leftDate = left.createdAt ?? .distantPast
            let rightDate = right.createdAt ?? .distantPast
            return currentSort == .latest ? leftDate > rightDate : leftDate < rightDate
        }

        filteredOrders = result
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if filteredOrders.isEmpty {
            if trimmedQuery.isEmpty {
                emptyLabel.text = "표시할 주문이 없습니다."
            } else {
                emptyLabel.text = "검색 결과가 없습니다."
            }
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
    }
}

extension AdminOrderListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredOrders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminOrderListCell.reuseIdentifier,
            for: indexPath
        ) as! AdminOrderListCell
        let order = filteredOrders[indexPath.row]
        let isSelected = order.orderId == selectedOrderId
        cell.configure(order: order, isSelected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = filteredOrders[indexPath.row]
        selectedOrderId = order.orderId
        selectionSubject.send(order)
        tableView.reloadData()
    }
}

extension AdminOrderListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private enum OrderLookupFilter: CaseIterable {
    case all
    case pending
    case cooking
    case ready
    case completed

    var title: String {
        switch self {
        case .all:
            return "전체"
        case .pending:
            return "접수중"
        case .cooking:
            return "조리중"
        case .ready:
            return "픽업대기"
        case .completed:
            return "완료"
        }
    }

    func matches(order: OrderListItemEntity) -> Bool {
        switch self {
        case .all:
            return true
        case .pending:
            return order.currentOrderStatus == .pendingApproval
        case .cooking:
            return order.currentOrderStatus == .approved || order.currentOrderStatus == .inProgress
        case .ready:
            return order.currentOrderStatus == .readyForPickup
        case .completed:
            return order.currentOrderStatus == .pickedUp
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
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
        orderCodeLabel.numberOfLines = 1
        orderCodeLabel.lineBreakMode = .byTruncatingTail
        storeNameLabel.font = AppFont.body2
        storeNameLabel.textColor = AppColor.gray75
        storeNameLabel.numberOfLines = 2
        storeNameLabel.lineBreakMode = .byTruncatingTail
        timeLabel.font = AppFont.caption1
        timeLabel.textColor = AppColor.gray60
        timeLabel.numberOfLines = 1
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
        storeNameLabel.text = "\(menuSummaryText(for: order))\n\(order.totalPrice.formatted())원"
        timeLabel.isHidden = true
        statusLabel.text = order.currentOrderStatus.description
        let statusColor = statusColor(for: order.currentOrderStatus)
        statusLabel.backgroundColor = statusColor
        statusLabel.textColor = statusTextColor(for: order.currentOrderStatus)
        containerView.layer.borderColor = isSelected ? AppColor.deepSprout.cgColor : AppColor.gray30.cgColor
        containerView.backgroundColor = isSelected ? AppColor.brightSprout : AppColor.gray0
    }

    private func menuSummaryText(for order: OrderListItemEntity) -> String {
        guard let firstMenu = order.orderMenuList.first?.menu.name else {
            return "메뉴 정보 없음"
        }
        let extraCount = max(order.orderMenuList.count - 1, 0)
        if extraCount > 0 {
            return "\(firstMenu) 외 \(extraCount)건"
        }
        return firstMenu
    }

    private func statusColor(for status: OrderStatusEntity) -> UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.gray45
        case .approved, .inProgress:
            return AppColor.deepSprout
        case .readyForPickup:
            return AppColor.blackSprout
        case .pickedUp:
            return AppColor.gray60
        }
    }

    private func statusTextColor(for status: OrderStatusEntity) -> UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.gray90
        default:
            return AppColor.gray0
        }
    }
}

private enum Layout {
    static let headerInsets = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
    static let headerSpacing: CGFloat = 8
}
