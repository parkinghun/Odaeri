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

    private let viewModel: AdminOrderDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "왼쪽에서 주문을 선택하세요."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor.systemGray
        label.textAlignment = .center
        return label
    }()

    private let topBar = UIView()
    private let orderCodeLabel = UILabel()
    private let totalPriceLabel = UILabel()
    private let pickupBadge = UILabel()
    private let rejectButton = UIButton(type: .system)
    private let timeControlView = UIView()
    private let timeMinusButton = UIButton(type: .system)
    private let timePlusButton = UIButton(type: .system)
    private let timeValueLabel = UILabel()
    private let acceptButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let menuSectionView = UIView()
    private let requestSectionView = UIView()

    init(viewModel: AdminOrderDetailViewModel = AdminOrderDetailViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        updateEmptyState()
    }

    func configure(order: OrderListItemEntity?) {
        viewModel.updateOrder(order)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private extension AdminOrderDetailViewController {
    func setupUI() {
        view.backgroundColor = UIColor.systemGray6

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        setupTopBar()
        setupContent()
    }

    func setupTopBar() {
        view.addSubview(topBar)
        topBar.backgroundColor = .white
        topBar.layer.shadowColor = UIColor.black.cgColor
        topBar.layer.shadowOpacity = 0.06
        topBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        topBar.layer.shadowRadius = 10

        topBar.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(96)
        }

        orderCodeLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        orderCodeLabel.textColor = AppColor.gray100

        totalPriceLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        totalPriceLabel.textColor = AppColor.gray75

        pickupBadge.text = "픽업"
        pickupBadge.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        pickupBadge.textColor = AppColor.gray0
        pickupBadge.backgroundColor = AppColor.blackSprout
        pickupBadge.layer.cornerRadius = 10
        pickupBadge.clipsToBounds = true
        pickupBadge.textAlignment = .center

        let titleSpacer = UIView()
        titleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [orderCodeLabel, pickupBadge, titleSpacer])
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center

        let titleStack = UIStackView(arrangedSubviews: [titleRow, totalPriceLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 6

        rejectButton.setTitle("거부", for: .normal)
        rejectButton.setTitleColor(UIColor.systemRed, for: .normal)
        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        rejectButton.backgroundColor = UIColor.systemGray5
        rejectButton.layer.cornerRadius = 12
        rejectButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        rejectButton.addTarget(self, action: #selector(handleReject), for: .touchUpInside)

        timeControlView.backgroundColor = AppColor.gray15
        timeControlView.layer.cornerRadius = 16
        timeControlView.layer.borderWidth = 1
        timeControlView.layer.borderColor = AppColor.gray30.cgColor

        timeMinusButton.setTitle("–", for: .normal)
        timeMinusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        timeMinusButton.setTitleColor(AppColor.gray90, for: .normal)
        timeMinusButton.addTarget(self, action: #selector(handleTimeMinus), for: .touchUpInside)

        timePlusButton.setTitle("+", for: .normal)
        timePlusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        timePlusButton.setTitleColor(AppColor.gray90, for: .normal)
        timePlusButton.addTarget(self, action: #selector(handleTimePlus), for: .touchUpInside)

        timeValueLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        timeValueLabel.textColor = AppColor.gray90
        timeValueLabel.textAlignment = .center

        timeControlView.addSubview(timeMinusButton)
        timeControlView.addSubview(timeValueLabel)
        timeControlView.addSubview(timePlusButton)

        timeMinusButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(24)
        }

        timePlusButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(24)
        }

        timeValueLabel.snp.makeConstraints {
            $0.leading.equalTo(timeMinusButton.snp.trailing).offset(8)
            $0.trailing.equalTo(timePlusButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        acceptButton.setTitle("접수", for: .normal)
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        acceptButton.backgroundColor = AppColor.blackSprout
        acceptButton.layer.cornerRadius = 12
        acceptButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
        acceptButton.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)

        let controlStack = UIStackView(arrangedSubviews: [rejectButton, timeControlView, acceptButton])
        controlStack.axis = .horizontal
        controlStack.spacing = 16
        controlStack.alignment = .center
        controlStack.tag = Layout.controlStackTag

        topBar.addSubview(titleStack)
        topBar.addSubview(controlStack)

        titleStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }

        pickupBadge.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.width.equalTo(48)
        }

        controlStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }

        timeControlView.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.width.equalTo(180)
        }
    }

    func setupContent() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints {
            $0.top.equalTo(topBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(24)
            $0.width.equalToSuperview().offset(-48)
        }

        setupRequestSection()
        setupMenuSection()
    }

    func setupMenuSection() {
        menuSectionView.backgroundColor = .white
        menuSectionView.layer.cornerRadius = 16
        menuSectionView.layer.shadowColor = UIColor.black.cgColor
        menuSectionView.layer.shadowOpacity = 0.06
        menuSectionView.layer.shadowOffset = CGSize(width: 0, height: 6)
        menuSectionView.layer.shadowRadius = 12

        let titleLabel = sectionTitle("주문정보")
        let headerRow = menuHeaderRow()
        let headerDivider = UIView()
        headerDivider.backgroundColor = AppColor.gray30
        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = 10
        listStack.tag = Layout.menuListTag

        let totalDivider = UIView()
        totalDivider.backgroundColor = AppColor.gray30

        let totalTitleLabel = UILabel()
        totalTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        totalTitleLabel.textColor = AppColor.gray100
        totalTitleLabel.text = "총 금액"

        let totalValueLabel = UILabel()
        totalValueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        totalValueLabel.textColor = AppColor.gray100
        totalValueLabel.textAlignment = .right
        totalValueLabel.tag = Layout.totalLabelTag

        let totalRow = UIStackView(arrangedSubviews: [totalTitleLabel, totalValueLabel])
        totalRow.axis = .horizontal
        totalRow.alignment = .center
        totalRow.spacing = 12

        let container = UIStackView(arrangedSubviews: [titleLabel, headerRow, headerDivider, listStack, totalDivider, totalRow])
        container.axis = .vertical
        container.spacing = 16

        menuSectionView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }

        headerDivider.snp.makeConstraints {
            $0.height.equalTo(1)
        }

        totalDivider.snp.makeConstraints {
            $0.height.equalTo(1)
        }

        container.setCustomSpacing(18, after: titleLabel)
        container.setCustomSpacing(12, after: headerRow)
        container.setCustomSpacing(14, after: headerDivider)
        container.setCustomSpacing(100, after: listStack)
        container.setCustomSpacing(12, after: totalDivider)

        contentStack.addArrangedSubview(menuSectionView)
    }

    func setupRequestSection() {
        requestSectionView.backgroundColor = .white
        requestSectionView.layer.cornerRadius = 16
        requestSectionView.layer.shadowColor = UIColor.black.cgColor
        requestSectionView.layer.shadowOpacity = 0.06
        requestSectionView.layer.shadowOffset = CGSize(width: 0, height: 6)
        requestSectionView.layer.shadowRadius = 12

        let titleLabel = sectionTitle("요청 사항")
        let requestLabel = UILabel()
        requestLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        requestLabel.textColor = AppColor.gray90
        requestLabel.numberOfLines = 0
        requestLabel.tag = Layout.requestLabelTag

        let stack = UIStackView(arrangedSubviews: [titleLabel, requestLabel])
        stack.axis = .vertical
        stack.spacing = 12

        requestSectionView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }

        contentStack.addArrangedSubview(requestSectionView)
    }

    func bind() {
        viewModel.$order
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.applyOrder(order)
            }
            .store(in: &cancellables)

        viewModel.$estimatedMinutes
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] minutes in
                self?.timeValueLabel.text = "\(minutes)~\(minutes + 5)분"
            }
            .store(in: &cancellables)
    }

    func updateEmptyState() {
        let hasOrder = viewModel.order != nil
        emptyLabel.isHidden = hasOrder
        topBar.isHidden = !hasOrder
        scrollView.isHidden = !hasOrder
    }

    func applyOrder(_ order: OrderListItemEntity?) {
        updateEmptyState()
        guard let order else { return }

        orderCodeLabel.text = "#\(order.orderCode)"
        totalPriceLabel.text = makeOrderSummary(order)
        updateMenuSection(order)
        updateRequestSection(order)
        updateActionButtons(order)
    }

    func updateMenuSection(_ order: OrderListItemEntity) {
        guard let listStack = menuSectionView.viewWithTag(Layout.menuListTag) as? UIStackView else { return }
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for menu in order.orderMenuList {
            listStack.addArrangedSubview(menuRow(menu))
        }

        if let totalLabel = menuSectionView.viewWithTag(Layout.totalLabelTag) as? UILabel {
            totalLabel.text = formatPrice(order.totalPrice)
        }
    }

    func updateRequestSection(_ order: OrderListItemEntity) {
        guard let requestLabel = requestSectionView.viewWithTag(Layout.requestLabelTag) as? UILabel else { return }
        requestLabel.text = mockRequestText(for: order.orderCode)
    }

    func updateActionButtons(_ order: OrderListItemEntity) {
        let status = order.currentOrderStatus
        acceptButton.setTitle(status.adminPrimaryActionTitle, for: .normal)
        let isCompleted = status == .pickedUp
        acceptButton.isEnabled = !isCompleted
        acceptButton.backgroundColor = isCompleted ? UIColor.systemGray3 : AppColor.blackSprout
        rejectButton.isHidden = isCompleted
        timeControlView.isHidden = isCompleted
    }

    func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColor.gray100
        return label
    }

    func menuHeaderRow() -> UIView {
        let nameLabel = headerLabel("메뉴")
        let qtyLabel = headerLabel("수량")
        let priceLabel = headerLabel("금액")
        qtyLabel.textAlignment = .right
        priceLabel.textAlignment = .right

        return menuRowContainer(nameLabel: nameLabel, qtyLabel: qtyLabel, priceLabel: priceLabel)
    }

    func menuRow(_ menu: OrderMenuEntity) -> UIView {
        let nameLabel = bodyLabel(menu.menu.name)
        let qtyLabel = bodyLabel("\(menu.quantity)")
        let priceLabel = bodyLabel(formatPrice(menu.menu.price * menu.quantity))
        qtyLabel.textAlignment = .right
        priceLabel.textAlignment = .right

        return menuRowContainer(nameLabel: nameLabel, qtyLabel: qtyLabel, priceLabel: priceLabel)
    }

    func headerLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = AppColor.gray60
        return label
    }

    func bodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = AppColor.gray90
        return label
    }

    func menuRowContainer(nameLabel: UILabel, qtyLabel: UILabel, priceLabel: UILabel) -> UIView {
        let container = UIView()
        container.addSubview(nameLabel)
        container.addSubview(qtyLabel)
        container.addSubview(priceLabel)

        container.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(28)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.greaterThanOrEqualTo(90)
        }

        qtyLabel.snp.makeConstraints {
            $0.trailing.equalTo(priceLabel.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(50)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(qtyLabel.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
        }

        return container
    }

    func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formatted)원"
    }

    func makeOrderSummary(_ order: OrderListItemEntity) -> String {
        let menuCount = order.orderMenuList.count
        let total = formatPrice(order.totalPrice)
        return "메뉴 \(menuCount)개 · 총 \(total) (결제완료)"
    }

    func mockRequestText(for orderCode: String) -> String {
        switch orderCode {
        case "A-1001":
            return "얼음 많이, 시럽 적게 부탁드려요."
        case "A-1002":
            return "치즈케이크는 냉장 포장 부탁드립니다."
        case "B-2001":
            return "샌드위치는 반으로 컷팅해주세요."
        case "B-2002":
            return "뜨거운 음료는 따로 포장 부탁드려요."
        case "B-2003":
            return "빨대 2개, 냅킨 넉넉히 부탁드려요."
        default:
            return "요청 사항 없음"
        }
    }

    @objc func handleReject() {
        guard viewModel.order != nil else { return }
        updateStatusSubject.send(.pendingApproval)
    }

    @objc func handlePrimaryAction() {
        guard let order = viewModel.order else { return }
        let nextStatus: OrderStatusEntity

        switch order.currentOrderStatus {
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

    @objc func handleTimeMinus() {
        let next = max(5, viewModel.estimatedMinutes - 5)
        viewModel.updateEstimatedMinutes(next)
    }

    @objc func handleTimePlus() {
        let next = min(120, viewModel.estimatedMinutes + 5)
        viewModel.updateEstimatedMinutes(next)
    }

    enum Layout {
        static let menuListTag = 1201
        static let requestLabelTag = 1202
        static let controlStackTag = 1203
        static let totalLabelTag = 1204
    }
}

private extension OrderStatusEntity {
    var adminPrimaryActionTitle: String {
        switch self {
        case .pendingApproval:
            return "접수"
        case .approved:
            return "조리 시작"
        case .inProgress:
            return "픽업 대기"
        case .readyForPickup:
            return "픽업 완료"
        case .pickedUp:
            return "완료됨"
        }
    }
}
