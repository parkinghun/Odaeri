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
    private var pickupMinutes = Layout.defaultPickupMinutes

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()

    private let headerView = AdminOrderHeaderView()
    private let summaryView = AdminOrderSummaryView()
    private let menuView = AdminOrderMenuListView()
    private let infoPanelView = AdminOrderInfoPanelView()

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
        bind()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = Layout.sectionSpacing
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.pageInsets)
        }

        let mainRowStack = UIStackView(arrangedSubviews: [summaryView, menuView])
        mainRowStack.axis = .horizontal
        mainRowStack.spacing = Layout.columnSpacing
        mainRowStack.distribution = .fillEqually

        contentStack.addArrangedSubview(headerView)
        contentStack.addArrangedSubview(mainRowStack)
        contentStack.addArrangedSubview(infoPanelView)

        summaryView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(Layout.minimumSummaryHeight)
        }

        menuView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(Layout.minimumMenuHeight)
        }
    }

    private func bind() {
        headerView.onAccept = { [weak self] in
            self?.updateStatusSubject.send(.approved)
        }
        headerView.onReject = { [weak self] in
            self?.showRejectAlert()
        }
        infoPanelView.onIncrease = { [weak self] in
            self?.adjustPickupMinutes(delta: Layout.pickupStep)
        }
        infoPanelView.onDecrease = { [weak self] in
            self?.adjustPickupMinutes(delta: -Layout.pickupStep)
        }
    }

    func configure(order: OrderListItemEntity?) {
        currentOrder = order
        pickupMinutes = Layout.defaultPickupMinutes
        emptyLabel.isHidden = order != nil
        scrollView.isHidden = order == nil

        guard let order else { return }
        let isStoreOpen = checkStoreOpen(closeTime: order.store.close)
        headerView.configure(order: order, isStoreOpen: isStoreOpen)
        summaryView.configure(order: order)
        menuView.configure(order: order)
        updatePickupInfo()
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func updatePickupInfo() {
        guard let order = currentOrder else { return }
        let baseDate = order.paidAt ?? order.createdAt ?? Date()
        let deadline = Calendar.current.date(byAdding: .minute, value: pickupMinutes, to: baseDate) ?? baseDate
        let deadlineText = DateFormatter.timeDisplay.string(from: deadline)
        let paymentStatusText = order.paidAt == nil ? "결제 대기" : "결제 완료"
        infoPanelView.update(
            pickupMinutes: pickupMinutes,
            pickupDeadlineText: "픽업 마감 \(deadlineText)",
            paymentStatusText: paymentStatusText
        )
    }

    private func adjustPickupMinutes(delta: Int) {
        pickupMinutes = max(Layout.minimumPickupMinutes, min(Layout.maximumPickupMinutes, pickupMinutes + delta))
        updatePickupInfo()
    }

    private func checkStoreOpen(closeTime: String) -> Bool {
        guard let closeDate = Self.closeTimeFormatter.date(from: closeTime) else { return true }
        let now = Date()
        let calendar = Calendar.current
        let closeComponents = calendar.dateComponents([.hour, .minute], from: closeDate)
        var dayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dayComponents.hour = closeComponents.hour
        dayComponents.minute = closeComponents.minute
        guard let todayClose = calendar.date(from: dayComponents) else { return true }
        return now < todayClose
    }

    private func showRejectAlert() {
        let alert = UIAlertController(title: "주문 거부", message: "거부 기능은 준비 중입니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private static let closeTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private final class AdminOrderHeaderView: UIView {
    private let storeNameLabel = UILabel()
    private let openBadge = AdminOrderOpenBadgeView()
    private let orderCodeLabel = UILabel()
    private let paidAtLabel = UILabel()
    private let statusLabel = UILabel()
    private let acceptButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let actionStack = UIStackView()

    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0

        storeNameLabel.font = AppFont.title1
        storeNameLabel.textColor = AppColor.gray90

        orderCodeLabel.font = AppFont.body2Bold
        orderCodeLabel.textColor = AppColor.gray90

        paidAtLabel.font = AppFont.body2
        paidAtLabel.textColor = AppColor.gray75

        statusLabel.font = AppFont.body2Bold
        statusLabel.textColor = AppColor.gray0
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = AppColor.gray90
        statusLabel.clipsToBounds = true

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

        actionStack.axis = .horizontal
        actionStack.spacing = Layout.buttonSpacing
        actionStack.addArrangedSubview(acceptButton)
        actionStack.addArrangedSubview(rejectButton)

        let storeRow = UIStackView(arrangedSubviews: [storeNameLabel, openBadge, UIView()])
        storeRow.axis = .horizontal
        storeRow.spacing = Layout.textSpacing
        storeRow.alignment = .center

        let orderRow = UIStackView(arrangedSubviews: [orderCodeLabel, paidAtLabel])
        orderRow.axis = .horizontal
        orderRow.spacing = Layout.textSpacing

        let leftStack = UIStackView(arrangedSubviews: [storeRow, orderRow])
        leftStack.axis = .vertical
        leftStack.spacing = Layout.textSpacing

        let rightStack = UIStackView(arrangedSubviews: [statusLabel, actionStack])
        rightStack.axis = .vertical
        rightStack.spacing = Layout.textSpacing
        rightStack.alignment = .trailing

        let container = UIStackView(arrangedSubviews: [leftStack, rightStack])
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .equalSpacing

        addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        statusLabel.layer.cornerRadius = statusLabel.bounds.height / 2
    }

    func configure(order: OrderListItemEntity, isStoreOpen: Bool) {
        storeNameLabel.text = order.store.name
        openBadge.update(isOpen: isStoreOpen)
        orderCodeLabel.text = "픽업 주문 번호 \(order.orderCode)"
        let paidAtText = order.paidAt ?? order.createdAt
        let dateText = paidAtText.map { DateFormatter.dotDisplay.string(from: $0) } ?? "결제 시간 없음"
        paidAtLabel.text = "결제일자 \(dateText)"

        if order.currentOrderStatus == .pendingApproval {
            statusLabel.isHidden = true
            actionStack.isHidden = false
        } else {
            statusLabel.isHidden = false
            statusLabel.text = order.currentOrderStatus.description
            actionStack.isHidden = true
        }
    }

    @objc private func handleAccept() {
        onAccept?()
    }

    @objc private func handleReject() {
        onReject?()
    }
}

private final class AdminOrderOpenBadgeView: UIView {
    private let dotView = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.badgeCornerRadius

        dotView.layer.cornerRadius = Layout.dotSize / 2

        titleLabel.font = AppFont.caption1
        titleLabel.textColor = AppColor.gray90

        let stack = UIStackView(arrangedSubviews: [dotView, titleLabel])
        stack.axis = .horizontal
        stack.spacing = Layout.textSpacing
        stack.alignment = .center

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.badgeInsets)
        }
        dotView.snp.makeConstraints {
            $0.size.equalTo(Layout.dotSize)
        }
    }

    func update(isOpen: Bool) {
        titleLabel.text = isOpen ? "영업 중" : "영업 종료"
        dotView.backgroundColor = isOpen ? AppColor.deepSprout : AppColor.gray60
    }
}

private final class AdminOrderSummaryView: UIView {
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.text = "주문 요약"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        stackView.axis = .vertical
        stackView.spacing = Layout.rowSpacing

        let container = UIStackView(arrangedSubviews: [titleLabel, stackView])
        container.axis = .vertical
        container.spacing = Layout.sectionSpacing

        addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cardInsets)
        }
    }

    func configure(order: OrderListItemEntity) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let createdText = order.createdAt.map { DateFormatter.fullDisplay.string(from: $0) } ?? "시간 정보 없음"
        let paidText = order.paidAt.map { DateFormatter.fullDisplay.string(from: $0) } ?? "결제 정보 없음"
        let latestTimeline = order.orderStatusTimeline.last
        let timelineDate = latestTimeline?.changedAt.map { DateFormatter.fullDisplay.string(from: $0) } ?? "시간 정보 없음"
        let timelineText = "\(latestTimeline?.status.description ?? order.currentOrderStatus.description) · \(timelineDate)"
        let hashTags = order.store.hashTags.joined(separator: ", ")
        let locationText = "위도 \(order.store.latitude), 경도 \(order.store.longitude)"

        let rows = [
            AdminSummaryRowView(title: "주문 생성일", value: createdText),
            AdminSummaryRowView(title: "결제일", value: paidText),
            AdminSummaryRowView(title: "상태 이력", value: timelineText),
            AdminSummaryRowView(title: "카테고리", value: order.store.category),
            AdminSummaryRowView(title: "해시태그", value: hashTags.isEmpty ? "정보 없음" : hashTags),
            AdminSummaryRowView(title: "가게 위치", value: locationText)
        ]

        rows.forEach { row in
            stackView.addArrangedSubview(row)
        }
    }
}

private final class AdminSummaryRowView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        setupUI()
        titleLabel.text = title
        valueLabel.text = value
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.font = AppFont.caption1
        titleLabel.textColor = AppColor.gray60

        valueLabel.font = AppFont.body2
        valueLabel.textColor = AppColor.gray90
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = Layout.textSpacing

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

private final class AdminOrderMenuListView: UIView {
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let dividerView = UIView()
    private let totalLabel = UILabel()
    private let spacerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.text = "메뉴 리스트"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        stackView.axis = .vertical
        stackView.spacing = Layout.rowSpacing

        dividerView.backgroundColor = AppColor.gray30

        totalLabel.font = AppFont.body1Bold
        totalLabel.textColor = AppColor.gray90
        totalLabel.textAlignment = .right

        let container = UIStackView(arrangedSubviews: [titleLabel, stackView, spacerView, dividerView, totalLabel])
        container.axis = .vertical
        container.spacing = Layout.sectionSpacing

        addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cardInsets)
        }

        dividerView.snp.makeConstraints {
            $0.height.equalTo(1)
        }

        stackView.setContentHuggingPriority(.required, for: .vertical)
        totalLabel.setContentHuggingPriority(.required, for: .vertical)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    func configure(order: OrderListItemEntity) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        order.orderMenuList.forEach { item in
            let row = AdminMenuRowView(item: item)
            stackView.addArrangedSubview(row)
        }
        totalLabel.text = "총 금액 \(order.totalPrice.formatted())원"
    }
}

private final class AdminMenuRowView: UIView {
    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()
    private let priceLabel = UILabel()
    private let tagLabel = UILabel()

    init(item: OrderMenuEntity) {
        super.init(frame: .zero)
        setupUI()
        configure(item: item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        nameLabel.font = AppFont.body2
        nameLabel.textColor = AppColor.gray90
        nameLabel.numberOfLines = 0

        quantityLabel.font = AppFont.caption1
        quantityLabel.textColor = AppColor.gray60

        priceLabel.font = AppFont.caption1
        priceLabel.textColor = AppColor.gray75

        tagLabel.font = AppFont.caption2
        tagLabel.textColor = AppColor.gray60

        let mainRow = UIStackView(arrangedSubviews: [nameLabel, quantityLabel, priceLabel])
        mainRow.axis = .horizontal
        mainRow.alignment = .center
        mainRow.distribution = .equalSpacing

        let container = UIStackView(arrangedSubviews: [mainRow, tagLabel])
        container.axis = .vertical
        container.spacing = Layout.textSpacing

        addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configure(item: OrderMenuEntity) {
        nameLabel.text = item.menu.name
        quantityLabel.text = "x\(item.quantity)"
        priceLabel.text = "\(item.menu.price.formatted())원"
        tagLabel.text = item.menu.tags.first.map { "태그: \($0)" } ?? ""
        tagLabel.isHidden = item.menu.tags.first == nil
    }
}

private final class AdminOrderInfoPanelView: UIView {
    private let titleLabel = UILabel()
    private let pickupValueLabel = UILabel()
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let deadlineLabel = UILabel()
    private let paymentStatusLabel = UILabel()
    private let cancelButton = UIButton(type: .system)

    var onIncrease: (() -> Void)?
    var onDecrease: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.text = "픽업 정보"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        pickupValueLabel.font = AppFont.title1
        pickupValueLabel.textColor = AppColor.gray90

        minusButton.setTitle("−", for: .normal)
        minusButton.setTitleColor(AppColor.gray90, for: .normal)
        minusButton.titleLabel?.font = AppFont.body1Bold
        minusButton.backgroundColor = AppColor.gray30
        minusButton.layer.cornerRadius = Layout.controlButtonCorner
        minusButton.addTarget(self, action: #selector(handleDecrease), for: .touchUpInside)

        plusButton.setTitle("+", for: .normal)
        plusButton.setTitleColor(AppColor.gray90, for: .normal)
        plusButton.titleLabel?.font = AppFont.body1Bold
        plusButton.backgroundColor = AppColor.gray30
        plusButton.layer.cornerRadius = Layout.controlButtonCorner
        plusButton.addTarget(self, action: #selector(handleIncrease), for: .touchUpInside)

        deadlineLabel.font = AppFont.body2
        deadlineLabel.textColor = AppColor.gray75

        paymentStatusLabel.font = AppFont.body2
        paymentStatusLabel.textColor = AppColor.gray75

        cancelButton.setTitle("주문 취소", for: .normal)
        cancelButton.setTitleColor(AppColor.gray90, for: .normal)
        cancelButton.backgroundColor = AppColor.gray30
        cancelButton.layer.cornerRadius = Layout.controlContainerCorner

        let controlStack = UIStackView(arrangedSubviews: [minusButton, pickupValueLabel, plusButton])
        controlStack.axis = .horizontal
        controlStack.spacing = Layout.controlSpacing
        controlStack.alignment = .center
        controlStack.layoutMargins = Layout.controlInsets
        controlStack.isLayoutMarginsRelativeArrangement = true
        controlStack.backgroundColor = AppColor.gray30
        controlStack.layer.cornerRadius = Layout.controlContainerCorner

        let actionRow = UIStackView(arrangedSubviews: [cancelButton, UIView(), controlStack])
        actionRow.axis = .horizontal
        actionRow.alignment = .center

        let container = UIStackView(arrangedSubviews: [titleLabel, deadlineLabel, paymentStatusLabel, actionRow])
        container.axis = .vertical
        container.spacing = Layout.sectionSpacing

        addSubview(container)
        container.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cardInsets)
        }

        cancelButton.snp.makeConstraints {
            $0.height.equalTo(Layout.controlButtonSize)
            $0.width.greaterThanOrEqualTo(Layout.cancelButtonWidth)
        }

        minusButton.snp.makeConstraints {
            $0.size.equalTo(Layout.controlButtonSize)
        }

        plusButton.snp.makeConstraints {
            $0.size.equalTo(Layout.controlButtonSize)
        }
    }

    func update(pickupMinutes: Int, pickupDeadlineText: String, paymentStatusText: String) {
        pickupValueLabel.text = "\(pickupMinutes)분"
        deadlineLabel.text = pickupDeadlineText
        paymentStatusLabel.text = paymentStatusText
    }

    @objc private func handleIncrease() {
        onIncrease?()
    }

    @objc private func handleDecrease() {
        onDecrease?()
    }
}

private enum Layout {
    static let pageInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    static let sectionSpacing: CGFloat = 20
    static let columnSpacing: CGFloat = 20
    static let rowSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 6
    static let cardInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardCornerRadius: CGFloat = 16
    static let statusCornerRadius: CGFloat = 12
    static let actionCornerRadius: CGFloat = 14
    static let actionInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    static let buttonSpacing: CGFloat = 8
    static let badgeCornerRadius: CGFloat = 12
    static let badgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    static let dotSize: CGFloat = 6
    static let controlButtonCorner: CGFloat = 14
    static let controlButtonSize: CGFloat = 40
    static let controlSpacing: CGFloat = 12
    static let controlInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    static let controlContainerCorner: CGFloat = 16
    static let cancelButtonWidth: CGFloat = 110
    static let minimumSummaryHeight: CGFloat = 220
    static let minimumMenuHeight: CGFloat = 220
    static let defaultPickupMinutes = 20
    static let minimumPickupMinutes = 0
    static let maximumPickupMinutes = 180
    static let pickupStep = 5
}
