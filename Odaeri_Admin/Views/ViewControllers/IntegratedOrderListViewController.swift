//
//  IntegratedOrderListViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit

protocol IntegratedOrderListViewControllerDelegate: AnyObject {
    func orderListViewController(_ controller: IntegratedOrderListViewController, didSelect order: Order)
}

final class IntegratedOrderListViewController: UIViewController {
    weak var delegate: IntegratedOrderListViewControllerDelegate?
    var onSelectOrder: ((Order) -> Void)?

    private enum Filter: Int, CaseIterable {
        case processing
        case completed
        case all

        var title: String {
            switch self {
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .all: return "All"
            }
        }
    }

    private var allOrders: [Order] = []
    private var filteredOrders: [Order] = []
    private var currentFilter: Filter = .processing
    private var searchText: String = ""

    private let headerContainer = UIView()
    private let searchBar = UISearchBar()
    private let filterControl = UISegmentedControl(items: Filter.allCases.map { $0.title })
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyFilters()
    }

    func updateOrders(_ orders: [Order]) {
        allOrders = orders
        applyFilters()
    }

    private func setupUI() {
        view.backgroundColor = .white

        headerContainer.backgroundColor = .white

        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search Order # or Menu"
        searchBar.delegate = self

        filterControl.selectedSegmentIndex = currentFilter.rawValue
        filterControl.addTarget(self, action: #selector(handleFilterChanged), for: .valueChanged)

        let headerStack = UIStackView(arrangedSubviews: [searchBar, filterControl])
        headerStack.axis = .vertical
        headerStack.spacing = 12

        view.addSubview(headerContainer)
        headerContainer.addSubview(headerStack)
        view.addSubview(tableView)

        headerContainer.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        headerStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(headerContainer.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.register(IntegratedOrderRowCell.self, forCellReuseIdentifier: IntegratedOrderRowCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    @objc private func handleFilterChanged() {
        currentFilter = Filter(rawValue: filterControl.selectedSegmentIndex) ?? .processing
        applyFilters()
    }

    private func applyFilters() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let baseFiltered = allOrders.filter { order in
            switch currentFilter {
            case .processing:
                return order.status == .pending || order.status == .cooking
            case .completed:
                return order.status == .completed
            case .all:
                return true
            }
        }

        let searched = baseFiltered.filter { order in
            if query.isEmpty { return true }
            let codeMatch = order.orderCode.lowercased().contains(query)
            let menuMatch = order.menus.contains { $0.name.lowercased().contains(query) }
            return codeMatch || menuMatch
        }

        filteredOrders = searched
        tableView.reloadData()
    }
}

extension IntegratedOrderListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchText = searchBar.text ?? ""
        applyFilters()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }
}

extension IntegratedOrderListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredOrders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IntegratedOrderRowCell.reuseIdentifier, for: indexPath) as! IntegratedOrderRowCell
        let order = filteredOrders[indexPath.row]
        cell.configure(with: order)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = filteredOrders[indexPath.row]
        delegate?.orderListViewController(self, didSelect: order)
        onSelectOrder?(order)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        96
    }
}

private final class IntegratedOrderRowCell: UITableViewCell {
    static let reuseIdentifier = "IntegratedOrderRowCell"

    private let containerView = UIView()
    private let statusIndicator = UIView()
    private var statusIndicatorWidthConstraint: Constraint?
    private let orderLabel = UILabel()
    private let priceLabel = UILabel()
    private let menuLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            containerView.layer.borderWidth = isSelected ? 2 : 0
            containerView.layer.borderColor = isSelected ? UIColor.black.withAlphaComponent(0.1).cgColor : UIColor.clear.cgColor
            statusIndicatorWidthConstraint?.update(offset: isSelected ? 10 : 6)
        }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.06
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8

        statusIndicator.layer.cornerRadius = 3

        orderLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        orderLabel.textColor = UIColor.black

        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = UIColor.black

        menuLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        menuLabel.textColor = UIColor.darkGray

        contentView.addSubview(containerView)
        containerView.addSubview(statusIndicator)
        containerView.addSubview(orderLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(menuLabel)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        statusIndicator.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            statusIndicatorWidthConstraint = $0.width.equalTo(6).constraint
        }

        orderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(statusIndicator.snp.trailing).offset(16)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(orderLabel)
        }

        menuLabel.snp.makeConstraints {
            $0.leading.equalTo(orderLabel)
            $0.top.equalTo(orderLabel.snp.bottom).offset(6)
            $0.trailing.equalTo(priceLabel)
        }
    }

    func configure(with order: Order) {
        orderLabel.text = order.orderCode
        priceLabel.text = "\(order.totalPrice)원"
        if let firstMenu = order.menus.first {
            let extraCount = max(0, order.menus.count - 1)
            menuLabel.text = extraCount > 0 ? "\(firstMenu.name) 외 \(extraCount)건" : firstMenu.name
        } else {
            menuLabel.text = "메뉴 없음"
        }
        statusIndicator.backgroundColor = order.status.indicatorColor
    }
}
