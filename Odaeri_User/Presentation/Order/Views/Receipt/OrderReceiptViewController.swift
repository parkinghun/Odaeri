//
//  OrderReceiptViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import SnapKit
import Combine

final class OrderReceiptViewController: UIViewController {
    private let order: OrderListItemEntity
    private let notificationCenter: NotificationCenter
    private let transitionDelegate = OrderReceiptTransitioningDelegate()
    private var actionButton: UIButton?

    var onStoreTapped: ((String) -> Void)?
    private let reviewActionSubject = PassthroughSubject<OrderListItemEntity, Never>()
    var reviewActionPublisher: AnyPublisher<OrderListItemEntity, Never> {
        reviewActionSubject.eraseToAnyPublisher()
    }

    private let scrollView = UIScrollView()
    private let paperView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.large
        return stackView
    }()

    init(order: OrderListItemEntity, notificationCenter: NotificationCenter) {
        self.order = order
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        buildContent()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(scrollView)
        scrollView.addSubview(paperView)
        paperView.addSubview(contentStackView)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        paperView.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide).offset(AppSpacing.large)
            $0.bottom.equalTo(scrollView.contentLayoutGuide).offset(-AppSpacing.large)
            $0.leading.equalTo(scrollView.contentLayoutGuide).offset(AppSpacing.large)
            $0.trailing.equalTo(scrollView.contentLayoutGuide).offset(-AppSpacing.large)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-AppSpacing.large * 2)
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.large)
            $0.bottom.equalToSuperview().offset(-AppSpacing.large)
        }

        notificationCenter.addObserver(
            self,
            selector: #selector(handleReviewCreated(_:)),
            name: .reviewCreated,
            object: nil
        )
    }

    private func buildContent() {
        let headerView = ReceiptHeaderView(order: order)
        headerView.onStoreTapped = { [weak self] in
            guard let self else { return }
            self.onStoreTapped?(self.order.store.id)
        }
        let menuSection = ReceiptMenuSectionView(menuItems: order.orderMenuList)
        let totalSection = ReceiptTotalSectionView(order: order)
        let timelineSection = ReceiptTimelineSectionView(timeline: order.orderStatusTimeline)

        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(ReceiptDashedLineView())
        contentStackView.addArrangedSubview(menuSection)
        contentStackView.addArrangedSubview(ReceiptDashedLineView())
        contentStackView.addArrangedSubview(totalSection)
        contentStackView.addArrangedSubview(ReceiptDashedLineView())
        contentStackView.addArrangedSubview(timelineSection)
        if order.currentOrderStatus == .pickedUp {
            let button = makeActionButton()
            self.actionButton = button
            contentStackView.addArrangedSubview(ReceiptDashedLineView())
            contentStackView.addArrangedSubview(button)
            button.snp.makeConstraints {
                $0.height.equalTo(44)
            }
        }
    }

    private func makeActionButton() -> UIButton {
        let button = UIButton(type: .system)
        let hasReview = order.review != nil
        button.setTitle(hasReview ? "리뷰 작성 완료" : "리뷰 작성하기", for: .normal)
        button.titleLabel?.font = AppFont.body1Bold
        if hasReview {
            button.setTitleColor(AppColor.gray75, for: .normal)
            button.backgroundColor = AppColor.gray30
            button.isEnabled = false
        } else {
            button.setTitleColor(AppColor.gray0, for: .normal)
            button.backgroundColor = AppColor.deepSprout
            button.isEnabled = true
        }
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(handleReviewAction), for: .touchUpInside)
        return button
    }

    @objc private func handleReviewAction() {
        reviewActionSubject.send(order)
    }

    @objc private func handleReviewCreated(_ notification: Notification) {
        print("[OrderReceipt] Review created notification received")
        guard let userInfo = notification.userInfo,
              let orderCode = userInfo["orderCode"] as? String else {
            print("[OrderReceipt] Missing userInfo data")
            return
        }

        print("[OrderReceipt] Review for orderCode: \(orderCode), current: \(order.orderCode)")
        guard orderCode == order.orderCode else {
            print("[OrderReceipt] OrderCode mismatch, ignoring")
            return
        }

        print("[OrderReceipt] Updating action button text")
        actionButton?.setTitle("리뷰 작성 완료", for: .normal)
        actionButton?.setTitleColor(AppColor.gray75, for: .normal)
        actionButton?.backgroundColor = AppColor.gray30
        actionButton?.isEnabled = false
    }
}

private final class ReceiptHeaderView: UIView {
    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        label.numberOfLines = 1
        return label
    }()

    private let statusBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3Bold
        label.textColor = AppColor.gray0
        label.textAlignment = .center
        label.backgroundColor = AppColor.deepSprout
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private let orderCodeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        return label
    }()

    private let orderDateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        return label
    }()

    private lazy var topRowStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeNameLabel, statusBadgeLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private lazy var metaStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [orderCodeLabel, orderDateLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        return stackView
    }()

    private lazy var infoStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topRowStack, metaStack])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private lazy var rootStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeImageView, infoStack])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.large
        stackView.alignment = .center
        return stackView
    }()

    var onStoreTapped: (() -> Void)?

    init(order: OrderListItemEntity) {
        super.init(frame: .zero)
        setupUI()
        configure(with: order)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(rootStack)
        rootStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        storeImageView.snp.makeConstraints {
            $0.size.equalTo(64)
        }

        statusBadgeLabel.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(60)
        }

        storeNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)

        storeNameLabel.isUserInteractionEnabled = true
        storeImageView.isUserInteractionEnabled = true
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(handleStoreTap))
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(handleStoreTap))
        storeNameLabel.addGestureRecognizer(nameTap)
        storeImageView.addGestureRecognizer(imageTap)
    }

    private func configure(with order: OrderListItemEntity) {
        storeImageView.setImage(url: order.store.storeImageUrls.first)
        storeNameLabel.text = order.store.name
        statusBadgeLabel.text = order.currentOrderStatus.description
        orderCodeLabel.text = "주문번호: \(order.orderCode)"
        if let createdAt = order.createdAt {
            orderDateLabel.text = DateFormatter.fullDisplay.string(from: createdAt)
        } else {
            orderDateLabel.text = "주문 일시 미확인"
        }
    }

    @objc private func handleStoreTap() {
        onStoreTapped?()
    }
}

private final class ReceiptMenuSectionView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    init(menuItems: [OrderMenuEntity]) {
        super.init(frame: .zero)
        setupUI()
        configure(items: menuItems)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configure(items: [OrderMenuEntity]) {
        items.forEach { item in
            let row = ReceiptMenuRowView(menu: item)
            stackView.addArrangedSubview(row)
        }
    }
}

private final class ReceiptMenuRowView: UIView {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray90
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .right
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        label.textAlignment = .right
        return label
    }()

    private lazy var rightStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [quantityLabel, priceLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.medium
        stackView.alignment = .center
        return stackView
    }()

    private lazy var rootStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, rightStack])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    init(menu: OrderMenuEntity) {
        super.init(frame: .zero)
        setupUI()
        configure(with: menu)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(rootStack)
        rootStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func configure(with menu: OrderMenuEntity) {
        nameLabel.text = menu.menu.name
        quantityLabel.text = "x\(menu.quantity)"
        priceLabel.text = "\(menu.menu.price.formatted())원"
    }
}

private final class ReceiptTotalSectionView: UIView {
    private let totalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "결제 합계"
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray60
        return label
    }()

    private let totalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let paidAtLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [totalTitleLabel, totalPriceLabel, paidAtLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        return stackView
    }()

    init(order: OrderListItemEntity) {
        super.init(frame: .zero)
        setupUI()
        configure(with: order)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configure(with order: OrderListItemEntity) {
        totalPriceLabel.text = "\(order.totalPrice.formatted())원"
        if let paidAt = order.paidAt {
            paidAtLabel.text = "결제 완료: \(DateFormatter.fullDisplay.string(from: paidAt))"
        } else {
            paidAtLabel.text = "결제 완료: 미확인"
        }
    }
}

private final class ReceiptTimelineSectionView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.medium
        return stackView
    }()

    init(timeline: [OrderStatusTimelineEntity]) {
        super.init(frame: .zero)
        setupUI()
        configure(with: timeline)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configure(with timeline: [OrderStatusTimelineEntity]) {
        for (index, item) in timeline.enumerated() {
            let isLast = index == timeline.count - 1
            let view = ReceiptTimelineRowView(
                status: item.status,
                completed: item.completed,
                changedAt: item.changedAt,
                showsConnector: !isLast
            )
            stackView.addArrangedSubview(view)
        }
    }
}

private final class ReceiptTimelineRowView: UIView {
    private let indicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let connectorView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray60
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray45
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [statusLabel, timeLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        return stackView
    }()

    init(status: OrderStatusEntity, completed: Bool, changedAt: Date?, showsConnector: Bool) {
        super.init(frame: .zero)
        setupUI()
        configure(status: status, completed: completed, changedAt: changedAt, showsConnector: showsConnector)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(indicatorView)
        addSubview(connectorView)
        addSubview(textStack)

        indicatorView.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.size.equalTo(12)
        }

        connectorView.snp.makeConstraints {
            $0.centerX.equalTo(indicatorView)
            $0.top.equalTo(indicatorView.snp.bottom).offset(AppSpacing.xxSmall)
            $0.width.equalTo(2)
            $0.bottom.equalToSuperview()
        }

        textStack.snp.makeConstraints {
            $0.leading.equalTo(indicatorView.snp.trailing).offset(AppSpacing.medium)
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func configure(status: OrderStatusEntity, completed: Bool, changedAt: Date?, showsConnector: Bool) {
        statusLabel.text = status.description
        if let changedAt {
            timeLabel.text = DateFormatter.timeDisplay.string(from: changedAt)
        } else {
            timeLabel.text = "--"
        }

        let activeColor = AppColor.deepSprout
        let inactiveColor = AppColor.gray30
        indicatorView.backgroundColor = completed ? activeColor : inactiveColor
        statusLabel.textColor = completed ? AppColor.gray90 : AppColor.gray60
        timeLabel.textColor = completed ? AppColor.gray60 : AppColor.gray45
        connectorView.isHidden = !showsConnector
        connectorView.backgroundColor = completed ? activeColor : inactiveColor
    }
}

private final class ReceiptDashedLineView: UIView {
    private let dashLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        dashLayer.strokeColor = AppColor.gray30.cgColor
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [4, 4]
        layer.addSublayer(dashLayer)
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        dashLayer.path = path.cgPath
        dashLayer.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
}
