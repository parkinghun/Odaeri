//
//  IntegratedOrderListViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit

protocol IntegratedOrderListViewControllerDelegate: AnyObject {
    func orderListViewController(_ controller: IntegratedOrderListViewController, didSelect order: OrderListItemEntity)
}

final class IntegratedOrderListViewController: UIViewController {
    enum InitialFilter {
        case processing
        case completed
    }
    weak var delegate: IntegratedOrderListViewControllerDelegate?
    var onSelectOrder: ((OrderListItemEntity) -> Void)?

    private enum Filter {
        case processing
        case completed
    }

    enum SortOrder {
        case latest
        case oldest

        mutating func toggle(to order: SortOrder) {
            self = order
        }
    }

    private enum SectionType {
        case pending
        case processing
        case completed

        var title: String? {
            switch self {
            case .pending: return "신규"
            case .processing: return "진행"
            case .completed: return "완료"
            }
        }
    }

    private struct SectionModel {
        let type: SectionType
        let orders: [OrderListItemEntity]
    }

    private var allOrders: [OrderListItemEntity] = []
    private var sections: [SectionModel] = []
    private var selectedOrderId: String?
    private var currentFilter: Filter = .processing
    private var currentSort: SortOrder = .latest

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(initialFilter: InitialFilter = .processing) {
        switch initialFilter {
        case .processing:
            currentFilter = .processing
        case .completed:
            currentFilter = .completed
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyFilters()
    }

    func updateOrders(_ orders: [OrderListItemEntity]) {
        allOrders = orders
        applyFilters()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray15
        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.backgroundColor = AppColor.gray15
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 8
        tableView.rowHeight = 120
        tableView.register(IntegratedOrderCardCell.self, forCellReuseIdentifier: IntegratedOrderCardCell.reuseIdentifier)
        tableView.register(IntegratedOrderHeaderView.self, forHeaderFooterViewReuseIdentifier: IntegratedOrderHeaderView.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func applyFilters() {
        switch currentFilter {
        case .processing:
            let pending = allOrders.filter { $0.currentOrderStatus == .pendingApproval }
            var processing = allOrders.filter {
                $0.currentOrderStatus == .approved ||
                $0.currentOrderStatus == .inProgress ||
                $0.currentOrderStatus == .readyForPickup
            }
            processing = sortOrders(processing)
            sections = [
                SectionModel(type: .pending, orders: pending),
                SectionModel(type: .processing, orders: processing)
            ]
        case .completed:
            let completed = sortOrders(allOrders.filter { $0.currentOrderStatus == .pickedUp })
            sections = [SectionModel(type: .completed, orders: completed)]
        }

        tableView.reloadData()
    }

    private func sortOrders(_ orders: [OrderListItemEntity]) -> [OrderListItemEntity] {
        switch currentSort {
        case .latest:
            return orders.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        case .oldest:
            return orders.sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
        }
    }
}

extension IntegratedOrderListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IntegratedOrderCardCell.reuseIdentifier, for: indexPath) as! IntegratedOrderCardCell
        let order = sections[indexPath.section].orders[indexPath.row]
        cell.configure(order: order)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = sections[indexPath.section].orders[indexPath.row]
        selectedOrderId = order.orderId
        delegate?.orderListViewController(self, didSelect: order)
        onSelectOrder?(order)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = sections[section].type
        guard let title = sectionType.title else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: IntegratedOrderHeaderView.reuseIdentifier) as? IntegratedOrderHeaderView
        switch sectionType {
        case .pending:
            let countText = "\(sections[section].orders.count)건"
            header?.configure(title: title, countText: countText, showsSort: false, currentSort: currentSort)
        case .processing, .completed:
            header?.configure(title: title, countText: nil, showsSort: true, currentSort: currentSort)
        }
        header?.onSortChanged = { [weak self] order in
            self?.currentSort.toggle(to: order)
            self?.applyFilters()
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].type.title == nil ? 0 : 40
    }
}

private final class IntegratedOrderHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "IntegratedOrderHeaderView"

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let sortStack = UIStackView()
    private let latestButton = UIButton(type: .system)
    private let oldestButton = UIButton(type: .system)

    var onSortChanged: ((IntegratedOrderListViewController.SortOrder) -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, countText: String?, showsSort: Bool, currentSort: IntegratedOrderListViewController.SortOrder) {
        titleLabel.text = title
        countLabel.text = countText
        countLabel.isHidden = countText == nil
        sortStack.isHidden = !showsSort

        let activeColor = AppColor.gray90
        let inactiveColor = AppColor.gray60
        latestButton.setTitleColor(currentSort == .latest ? activeColor : inactiveColor, for: .normal)
        oldestButton.setTitleColor(currentSort == .oldest ? activeColor : inactiveColor, for: .normal)
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(sortStack)
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = AppColor.gray90
        countLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        countLabel.textColor = AppColor.gray60

        latestButton.setTitle("최신순", for: .normal)
        latestButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        latestButton.addTarget(self, action: #selector(handleLatest), for: .touchUpInside)

        oldestButton.setTitle("과거순", for: .normal)
        oldestButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        oldestButton.addTarget(self, action: #selector(handleOldest), for: .touchUpInside)

        let separator = UILabel()
        separator.text = "|"
        separator.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        separator.textColor = AppColor.gray60

        sortStack.axis = .horizontal
        sortStack.spacing = 6
        sortStack.addArrangedSubview(latestButton)
        sortStack.addArrangedSubview(separator)
        sortStack.addArrangedSubview(oldestButton)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
        }

        sortStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    @objc private func handleLatest() {
        onSortChanged?(.latest)
    }

    @objc private func handleOldest() {
        onSortChanged?(.oldest)
    }
}

private final class IntegratedOrderCardCell: UITableViewCell {
    static let reuseIdentifier = "IntegratedOrderCardCell"

    private let containerView = UIView()
    private let statusBadge = PaddingLabel()
    private let orderLabel = UILabel()
    private let menuLabel = UILabel()
    private let textStack = UIStackView()
    private let dividerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        containerView.backgroundColor = AppColor.gray0
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.06
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8

        statusBadge.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 12
        statusBadge.clipsToBounds = true
        statusBadge.contentInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)
        statusBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        orderLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        orderLabel.textColor = AppColor.gray90

        menuLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        menuLabel.textColor = AppColor.gray90


        contentView.addSubview(containerView)
        containerView.addSubview(statusBadge)
        containerView.addSubview(textStack)
        containerView.addSubview(dividerView)

        containerView.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }

        statusBadge.snp.makeConstraints {
            $0.centerY.equalTo(textStack)
            $0.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(24)
        }

        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.addArrangedSubview(orderLabel)
        textStack.addArrangedSubview(menuLabel)

        textStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        dividerView.backgroundColor = AppColor.gray30
        dividerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    func configure(order: OrderListItemEntity) {
        orderLabel.text = "#\(order.orderCode)"
        menuLabel.text = makeMenuSummary(order)

        let status = order.currentOrderStatus
        statusBadge.text = status.adminBadgeTitle
        statusBadge.textColor = status.adminBadgeTextColor
        statusBadge.backgroundColor = status.adminBadgeBackgroundColor
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formatted)원"
    }

    private func makeMenuSummary(_ order: OrderListItemEntity) -> String {
        let count = order.orderMenuList.count
        return count > 0 ? "메뉴 \(count)개" : "메뉴 없음"
    }
}

private extension OrderStatusEntity {
    var adminBadgeTitle: String {
        switch self {
        case .pendingApproval: return "승인대기"
        case .approved: return "승인"
        case .inProgress: return "조리중"
        case .readyForPickup: return "픽업대기"
        case .pickedUp: return "완료"
        }
    }

    var adminBadgeBackgroundColor: UIColor {
        switch self {
        case .pendingApproval: return UIColor(hex: "FFF0F0")
        case .approved: return UIColor(hex: "E8F0FE")
        case .inProgress: return UIColor(hex: "FFF8E1")
        case .readyForPickup: return UIColor(hex: "E6F4EA")
        case .pickedUp: return AppColor.gray30
        }
    }

    var adminBadgeTextColor: UIColor {
        switch self {
        case .pendingApproval: return UIColor(hex: "E03131")
        case .approved: return UIColor(hex: "1967D2")
        case .inProgress: return UIColor(hex: "F57C00")
        case .readyForPickup: return UIColor(hex: "137333")
        case .pickedUp: return AppColor.gray75
        }
    }
}

private final class PaddingLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInsets.left + contentInsets.right,
                      height: size.height + contentInsets.top + contentInsets.bottom)
    }
}
