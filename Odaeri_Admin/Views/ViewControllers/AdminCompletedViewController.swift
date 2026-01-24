//
//  AdminCompletedViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminCompletedViewController: UIViewController {
    private let sortSubject = CurrentValueSubject<AdminSortOrder, Never>(.latest)
    private let selectionSubject = PassthroughSubject<OrderListItemEntity?, Never>()
    private var orders: [OrderListItemEntity] = []

    var sortPublisher: AnyPublisher<AdminSortOrder, Never> {
        sortSubject.eraseToAnyPublisher()
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

    func updateOrders(_ orders: [OrderListItemEntity]) {
        self.orders = orders
        tableView.reloadData()
    }
}

extension AdminCompletedViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminOrderCardCell.reuseIdentifier,
            for: indexPath
        ) as! AdminOrderCardCell
        let order = orders[indexPath.row]
        cell.configure(
            order: order,
            highlight: false,
            showsTimer: false,
            actionTitle: nil,
            actionHandler: nil
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = orders[indexPath.row]
        selectionSubject.send(order)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = AdminCompletedSortHeaderView()
        header.configure(selected: sortSubject.value)
        header.onSortChanged = { [weak self] order in
            self?.sortSubject.send(order)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Layout.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }
}

private final class AdminCompletedSortHeaderView: UIView {
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
        titleLabel.text = "완료 주문"

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

private enum Layout {
    static let headerHeight: CGFloat = 52
    static let rowHeight: CGFloat = 152
}
