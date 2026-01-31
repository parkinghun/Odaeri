//
//  AdminOrderDetailViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 01/30/26.
//

import UIKit
import Combine
import SnapKit

final class AdminOrderDetailViewController: UIViewController {
    private let updateStatusSubject = PassthroughSubject<OrderStatusEntity, Never>()
    var updateStatusPublisher: AnyPublisher<OrderStatusEntity, Never> {
        updateStatusSubject.eraseToAnyPublisher()
    }

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "왼쪽에서 주문을 선택하세요."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor.systemGray
        label.textAlignment = .center
        return label
    }()

    private let cardView = UIView()
    private let headerStack = UIStackView()
    private let orderCodeLabel = UILabel()
    private let timerBadgeLabel = UILabel()
    private let statusLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let menuSectionView = UIView()
    private let requestSectionView = UIView()
    private let paymentSectionView = UIView()

    private let footerContainer = UIView()
    private let footerStack = UIStackView()
    private let rejectButton = UIButton(type: .system)
    private let actionButton = UIButton(type: .system)

    private var currentOrder: Order?
    private var currentOrderEntity: OrderListItemEntity?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateEmptyState()
    }

    func configure(order: Order?) {
        currentOrder = order
        currentOrderEntity = nil
        updateEmptyState()
        guard let order else { return }
        applyOrder(order)
    }

    func configure(order: OrderListItemEntity?) {
        currentOrderEntity = order
        currentOrder = order.map { $0.toAdminOrder() }
        updateEmptyState()
        guard let mapped = currentOrder else { return }
        applyOrder(mapped)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        view.addSubview(cardView)
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.shadowRadius = 16

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().offset(-24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        cardView.addSubview(scrollView)
        cardView.addSubview(footerContainer)

        footerContainer.backgroundColor = .white

        footerContainer.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(60)
        }

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(footerContainer.snp.top)
        }

        scrollView.addSubview(headerStack)
        scrollView.addSubview(contentStack)

        headerStack.axis = .vertical
        headerStack.spacing = 8

        orderCodeLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        orderCodeLabel.textColor = .black

        timerBadgeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        timerBadgeLabel.textColor = .white
        timerBadgeLabel.backgroundColor = UIColor.systemGray
        timerBadgeLabel.layer.cornerRadius = 12
        timerBadgeLabel.layer.masksToBounds = true
        timerBadgeLabel.textAlignment = .center
        timerBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timerBadgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        statusLabel.textColor = UIColor.systemGray

        let headerRow = UIStackView(arrangedSubviews: [orderCodeLabel, timerBadgeLabel])
        headerRow.axis = .horizontal
        headerRow.spacing = 12
        headerRow.alignment = .center

        headerStack.addArrangedSubview(headerRow)
        headerStack.addArrangedSubview(statusLabel)

        headerStack.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide).offset(24)
            $0.leading.equalTo(scrollView.contentLayoutGuide).offset(24)
            $0.trailing.equalTo(scrollView.contentLayoutGuide).offset(-24)
        }

        timerBadgeLabel.snp.makeConstraints {
            $0.height.equalTo(24)
            $0.width.greaterThanOrEqualTo(72)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 20

        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(20)
            $0.leading.equalTo(scrollView.contentLayoutGuide).offset(24)
            $0.trailing.equalTo(scrollView.contentLayoutGuide).offset(-24)
            $0.bottom.equalTo(scrollView.contentLayoutGuide).offset(-24)
        }

        configureMenuSection()
        configureRequestSection()
        configurePaymentSection()

        footerStack.axis = .horizontal
        footerStack.spacing = 12
        footerStack.distribution = .fillEqually

        rejectButton.setTitle("거절", for: .normal)
        rejectButton.setTitleColor(UIColor.systemRed, for: .normal)
        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        rejectButton.backgroundColor = UIColor.systemGray5
        rejectButton.layer.cornerRadius = 10
        rejectButton.addTarget(self, action: #selector(handleReject), for: .touchUpInside)

        actionButton.setTitle("접수", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        actionButton.backgroundColor = UIColor.systemGreen
        actionButton.layer.cornerRadius = 10
        actionButton.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)

        footerContainer.addSubview(footerStack)
        footerStack.addArrangedSubview(rejectButton)
        footerStack.addArrangedSubview(actionButton)

        footerStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
    }

    private func updateEmptyState() {
        let hasOrder = currentOrder != nil
        emptyLabel.isHidden = hasOrder
        cardView.isHidden = !hasOrder
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func applyOrder(_ order: Order) {
        orderCodeLabel.text = order.orderCode
        statusLabel.text = order.status.displayName
        statusLabel.textColor = order.status.indicatorColor

        let elapsedMinutes = max(0, Int(Date().timeIntervalSince(order.orderTime) / 60))
        timerBadgeLabel.text = "경과 \(elapsedMinutes)분"

        updateMenuSection(order)
        updatePaymentSection(order)
        updateActionButtons(status: order.status)
    }

    private func updateActionButtons(status: OrderStatus) {
        switch status {
        case .pending:
            actionButton.setTitle("접수", for: .normal)
            actionButton.backgroundColor = UIColor.systemGreen
            actionButton.isEnabled = true
        case .cooking:
            actionButton.setTitle("완료", for: .normal)
            actionButton.backgroundColor = UIColor.systemGreen
            actionButton.isEnabled = true
        case .completed:
            actionButton.setTitle("완료됨", for: .normal)
            actionButton.backgroundColor = UIColor.systemGray3
            actionButton.isEnabled = false
        }
    }

    @objc private func handleReject() {
        guard currentOrderEntity != nil else { return }
        updateStatusSubject.send(.pendingApproval)
    }

    @objc private func handlePrimaryAction() {
        guard let entity = currentOrderEntity else { return }
        let nextStatus: OrderStatusEntity
        switch entity.currentOrderStatus {
        case .pendingApproval:
            nextStatus = .approved
        case .approved:
            nextStatus = .inProgress
        case .inProgress:
            nextStatus = .readyForPickup
        case .readyForPickup:
            nextStatus = .pickedUp
        case .pickedUp:
            return
        }
        updateStatusSubject.send(nextStatus)
    }

    private func configureMenuSection() {
        let titleLabel = sectionTitleLabel(text: "메뉴")
        let menuHeader = menuHeaderRow()
        let menuListStack = UIStackView()
        menuListStack.axis = .vertical
        menuListStack.spacing = 8
        menuListStack.tag = Layout.menuListTag

        let container = UIStackView(arrangedSubviews: [titleLabel, menuHeader, menuListStack])
        container.axis = .vertical
        container.spacing = 12

        menuSectionView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentStack.addArrangedSubview(menuSectionView)
    }

    private func configureRequestSection() {
        let titleLabel = sectionTitleLabel(text: "요청 사항")
        let requestLabel = UILabel()
        requestLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        requestLabel.textColor = UIColor.systemGray
        requestLabel.numberOfLines = 0
        requestLabel.text = "요청 사항 없음"
        requestLabel.tag = Layout.requestLabelTag

        let container = UIStackView(arrangedSubviews: [titleLabel, requestLabel])
        container.axis = .vertical
        container.spacing = 8

        requestSectionView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentStack.addArrangedSubview(requestSectionView)
    }

    private func configurePaymentSection() {
        let titleLabel = sectionTitleLabel(text: "고객 정보 및 결제 요약")
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.tag = Layout.paymentStackTag

        let container = UIStackView(arrangedSubviews: [titleLabel, infoStack])
        container.axis = .vertical
        container.spacing = 12

        paymentSectionView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentStack.addArrangedSubview(paymentSectionView)
    }

    private func updateMenuSection(_ order: Order) {
        guard let menuStack = menuSectionView.viewWithTag(Layout.menuListTag) as? UIStackView else { return }
        menuStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for menu in order.menus {
            let row = menuRow(name: menu.name, quantity: menu.quantity, price: menu.price)
            menuStack.addArrangedSubview(row)
        }
    }

    private func updatePaymentSection(_ order: Order) {
        guard let infoStack = paymentSectionView.viewWithTag(Layout.paymentStackTag) as? UIStackView else { return }
        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        infoStack.addArrangedSubview(infoRow(title: "매장", value: order.storeName))
        infoStack.addArrangedSubview(infoRow(title: "결제 금액", value: "\(order.totalPrice)원"))
        infoStack.addArrangedSubview(infoRow(title: "상태", value: order.status.displayName))
    }

    private func sectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }

    private func menuHeaderRow() -> UIStackView {
        let nameLabel = headerLabel(text: "메뉴")
        let qtyLabel = headerLabel(text: "수량")
        let priceLabel = headerLabel(text: "가격")

        let stack = UIStackView(arrangedSubviews: [nameLabel, qtyLabel, priceLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }

    private func menuRow(name: String, quantity: Int, price: Int) -> UIStackView {
        let nameLabel = bodyLabel(text: name)
        let qtyLabel = bodyLabel(text: "\(quantity)")
        let priceLabel = bodyLabel(text: "\(price)원")

        let stack = UIStackView(arrangedSubviews: [nameLabel, qtyLabel, priceLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }

    private func headerLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.systemGray
        return label
    }

    private func bodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.black
        return label
    }

    private func infoRow(title: String, value: String) -> UIStackView {
        let titleLabel = bodyLabel(text: title)
        titleLabel.textColor = UIColor.systemGray
        let valueLabel = bodyLabel(text: value)

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }

    private enum Layout {
        static let menuListTag = 101
        static let requestLabelTag = 102
        static let paymentStackTag = 103
    }
}

private extension OrderListItemEntity {
    func toAdminOrder() -> Order {
        let mappedStatus: OrderStatus
        switch currentOrderStatus {
        case .pendingApproval, .approved:
            mappedStatus = .pending
        case .inProgress:
            mappedStatus = .cooking
        case .readyForPickup, .pickedUp:
            mappedStatus = .completed
        }
        let menus = orderMenuList.map {
            Menu(name: $0.menu.name, price: $0.menu.price, quantity: $0.quantity, imageUrl: $0.menu.menuImageUrl)
        }
        return Order(
            orderCode: orderCode,
            totalPrice: totalPrice,
            status: mappedStatus,
            orderTime: createdAt ?? Date(),
            storeName: store.name,
            menus: menus
        )
    }
}
