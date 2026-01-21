//
//  AdminOrderDetailViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class AdminOrderDetailViewController: UIViewController {
    private let updateStatusSubject = PassthroughSubject<OrderStatusEntity, Never>()
    var updateStatusPublisher: AnyPublisher<OrderStatusEntity, Never> {
        updateStatusSubject.eraseToAnyPublisher()
    }

    private var currentOrder: OrderListItemEntity?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문 상세"
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColor.gray0
        tableView.register(AdminOrderSummaryCell.self, forCellReuseIdentifier: AdminOrderSummaryCell.reuseIdentifier)
        tableView.register(AdminOrderDividerCell.self, forCellReuseIdentifier: AdminOrderDividerCell.reuseIdentifier)
        tableView.register(AdminOrderInfoCell.self, forCellReuseIdentifier: AdminOrderInfoCell.reuseIdentifier)
        tableView.register(AdminOrderMenuDetailCell.self, forCellReuseIdentifier: AdminOrderMenuDetailCell.reuseIdentifier)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "왼쪽에서 주문을 선택하세요."
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        navigationItem.titleView = titleLabel

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    func configure(order: OrderListItemEntity?) {
        currentOrder = order
        emptyLabel.isHidden = order != nil
        tableView.isHidden = order == nil
        tableView.reloadData()
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension AdminOrderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let order = currentOrder else { return 0 }
        switch Section(rawValue: section) {
        case .summary:
            return 1
        case .divider:
            return 1
        case .menu:
            return order.orderMenuList.count + 1
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let order = currentOrder else { return UITableViewCell() }
        switch Section(rawValue: indexPath.section) {
        case .summary:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AdminOrderSummaryCell.reuseIdentifier,
                for: indexPath
            ) as! AdminOrderSummaryCell
            cell.configure(order: order)
            cell.onAccept = { [weak self] in
                self?.updateStatusSubject.send(.approved)
            }
            cell.onReject = { [weak self] in
                self?.showRejectAlert()
            }
            return cell
        case .divider:
            return tableView.dequeueReusableCell(
                withIdentifier: AdminOrderDividerCell.reuseIdentifier,
                for: indexPath
            )
        case .menu:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: AdminOrderInfoCell.reuseIdentifier,
                    for: indexPath
                ) as! AdminOrderInfoCell
                cell.configure(order: order)
                return cell
            }
            let menuItem = order.orderMenuList[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AdminOrderMenuDetailCell.reuseIdentifier,
                for: indexPath
            ) as! AdminOrderMenuDetailCell
            cell.configure(item: menuItem)
            return cell
        case .none:
            return UITableViewCell()
        }
    }

    private func showRejectAlert() {
        let alert = UIAlertController(title: "주문 거부", message: "거부 기능은 준비 중입니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private enum Section: Int {
    case summary
    case divider
    case menu
}

private final class AdminOrderSummaryCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderSummaryCell"

    private let orderCodeLabel = UILabel()
    private let summaryLabel = UILabel()
    private let statusLabel = UILabel()
    private let acceptButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let buttonStack = UIStackView()

    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppColor.gray0

        orderCodeLabel.font = AppFont.body1Bold
        orderCodeLabel.textColor = AppColor.gray90

        summaryLabel.font = AppFont.body2
        summaryLabel.textColor = AppColor.gray75

        statusLabel.font = AppFont.body2Bold
        statusLabel.textColor = AppColor.deepSprout
        statusLabel.textAlignment = .right

        acceptButton.setTitle("수락", for: .normal)
        acceptButton.setTitleColor(AppColor.gray0, for: .normal)
        acceptButton.backgroundColor = AppColor.deepSprout
        acceptButton.layer.cornerRadius = Layout.actionCornerRadius
        acceptButton.contentEdgeInsets = Layout.actionInsets
        acceptButton.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)

        rejectButton.setTitle("거부", for: .normal)
        rejectButton.setTitleColor(AppColor.gray90, for: .normal)
        rejectButton.backgroundColor = AppColor.gray30
        rejectButton.layer.cornerRadius = Layout.actionCornerRadius
        rejectButton.contentEdgeInsets = Layout.actionInsets
        rejectButton.addTarget(self, action: #selector(handleReject), for: .touchUpInside)

        buttonStack.axis = .horizontal
        buttonStack.spacing = Layout.buttonSpacing
        buttonStack.addArrangedSubview(acceptButton)
        buttonStack.addArrangedSubview(rejectButton)

        let titleStack = UIStackView(arrangedSubviews: [orderCodeLabel, summaryLabel])
        titleStack.axis = .vertical
        titleStack.spacing = Layout.textSpacing

        let rightStack = UIStackView(arrangedSubviews: [statusLabel, buttonStack])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = Layout.textSpacing

        let container = UIStackView(arrangedSubviews: [titleStack, rightStack])
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .equalSpacing

        contentView.addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cellInsets)
        }
    }

    func configure(order: OrderListItemEntity) {
        orderCodeLabel.text = "주문번호 \(order.orderCode)"
        summaryLabel.text = "메뉴 \(order.orderMenuList.count)건 · \(order.totalPrice.formatted())원"
        if order.currentOrderStatus == .pendingApproval {
            statusLabel.isHidden = true
            buttonStack.isHidden = false
        } else {
            statusLabel.isHidden = false
            statusLabel.text = order.currentOrderStatus.description
            buttonStack.isHidden = true
        }
    }

    @objc private func handleAccept() {
        onAccept?()
    }

    @objc private func handleReject() {
        onReject?()
    }
}

private final class AdminOrderDividerCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderDividerCell"

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
        backgroundColor = AppColor.gray0
        dividerView.backgroundColor = AppColor.gray30
        contentView.addSubview(dividerView)
        dividerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.cellInsets)
            $0.height.equalTo(1)
            $0.centerY.equalToSuperview()
        }
    }
}

private final class AdminOrderInfoCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderInfoCell"

    private let titleLabel = UILabel()
    private let storeLabel = UILabel()
    private let statusLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppColor.gray0

        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90
        titleLabel.text = "주문 정보"

        storeLabel.font = AppFont.body2
        storeLabel.textColor = AppColor.gray75

        statusLabel.font = AppFont.body2
        statusLabel.textColor = AppColor.gray75

        dateLabel.font = AppFont.body2
        dateLabel.textColor = AppColor.gray75

        let infoStack = UIStackView(arrangedSubviews: [storeLabel, statusLabel, dateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = Layout.textSpacing

        let stack = UIStackView(arrangedSubviews: [titleLabel, infoStack])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing

        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cellInsets)
        }
    }

    func configure(order: OrderListItemEntity) {
        storeLabel.text = "매장: \(order.store.name)"
        statusLabel.text = "상태: \(order.currentOrderStatus.description)"
        let dateText = order.createdAt.map { DateFormatter.fullDisplay.string(from: $0) } ?? "시간 정보 없음"
        dateLabel.text = "주문 시간: \(dateText)"
    }
}

private final class AdminOrderMenuDetailCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderMenuDetailCell"

    private let nameLabel = UILabel()
    private let optionLabel = UILabel()
    private let quantityLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppColor.gray0

        nameLabel.font = AppFont.body2
        nameLabel.textColor = AppColor.gray90
        nameLabel.numberOfLines = 0

        optionLabel.font = AppFont.caption1
        optionLabel.textColor = AppColor.gray60

        quantityLabel.font = AppFont.caption1
        quantityLabel.textColor = AppColor.gray60

        priceLabel.font = AppFont.caption1
        priceLabel.textColor = AppColor.gray75

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, optionLabel])
        nameStack.axis = .vertical
        nameStack.spacing = Layout.textSpacing

        let rowStack = UIStackView(arrangedSubviews: [nameStack, quantityLabel, priceLabel])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.distribution = .equalSpacing

        contentView.addSubview(rowStack)
        rowStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cellInsets)
        }
    }

    func configure(item: OrderMenuEntity) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        nameLabel.attributedText = NSAttributedString(
            string: item.menu.name,
            attributes: [.paragraphStyle: paragraph]
        )
        optionLabel.text = item.menu.tags.first.map { "옵션: \($0)" } ?? "옵션: 기본"
        quantityLabel.text = "x\(item.quantity)"
        priceLabel.text = "\(item.menu.price.formatted())원"
    }
}

private enum Layout {
    static let cellInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
    static let sectionSpacing: CGFloat = 10
    static let textSpacing: CGFloat = 6
    static let actionCornerRadius: CGFloat = 14
    static let actionInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    static let buttonSpacing: CGFloat = 8
}
