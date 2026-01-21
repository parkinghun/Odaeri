//
//  AdminOrderCardCell.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import SnapKit

final class AdminOrderCardCell: UITableViewCell {
    static let reuseIdentifier = "AdminOrderCardCell"

    private let containerView = UIView()
    private let orderCodeLabel = UILabel()
    private let storeNameLabel = UILabel()
    private let priceLabel = UILabel()
    private let statusLabel = UILabel()
    private let timerLabel = UILabel()
    private let timerCircleView = AdminTimerCircleView()
    private let timerStack = UIStackView()
    private let actionButton = UIButton(type: .system)
    private var actionHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        actionHandler = nil
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        containerView.layer.cornerRadius = Layout.containerCornerRadius
        containerView.layer.borderWidth = Layout.containerBorderWidth
        containerView.layer.borderColor = AppColor.gray30.cgColor
        containerView.backgroundColor = AppColor.gray0
        containerView.layer.shadowColor = AppColor.gray100.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 10
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.large)
        }

        orderCodeLabel.font = AppFont.body1Bold
        orderCodeLabel.textColor = AppColor.gray90
        storeNameLabel.font = AppFont.body2
        storeNameLabel.textColor = AppColor.gray75
        priceLabel.font = AppFont.body2Bold
        priceLabel.textColor = AppColor.gray90

        statusLabel.font = AppFont.caption1
        statusLabel.textColor = AppColor.gray0
        statusLabel.backgroundColor = AppColor.gray60
        statusLabel.layer.cornerRadius = Layout.statusCornerRadius
        statusLabel.clipsToBounds = true
        statusLabel.textAlignment = .center

        timerLabel.font = AppFont.caption1
        timerLabel.textColor = AppColor.gray75

        timerStack.axis = .horizontal
        timerStack.alignment = .center
        timerStack.spacing = AppSpacing.small
        timerStack.addArrangedSubview(timerCircleView)
        timerStack.addArrangedSubview(timerLabel)

        actionButton.titleLabel?.font = AppFont.body2Bold
        actionButton.setTitleColor(AppColor.gray0, for: .normal)
        actionButton.backgroundColor = AppColor.deepSprout
        actionButton.layer.cornerRadius = Layout.actionCornerRadius
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        let topStack = UIStackView(arrangedSubviews: [orderCodeLabel, statusLabel])
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.distribution = .equalSpacing

        let infoStack = UIStackView(arrangedSubviews: [storeNameLabel, priceLabel, timerStack])
        infoStack.axis = .vertical
        infoStack.spacing = AppSpacing.xSmall

        let contentStack = UIStackView(arrangedSubviews: [topStack, infoStack, actionButton])
        contentStack.axis = .vertical
        contentStack.spacing = AppSpacing.small

        containerView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.large)
        }

        statusLabel.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(Layout.statusMinWidth)
            $0.height.equalTo(Layout.statusHeight)
        }

        timerCircleView.snp.makeConstraints {
            $0.width.height.equalTo(Layout.timerSize)
        }

        actionButton.snp.makeConstraints {
            $0.height.equalTo(Layout.actionHeight)
        }
    }

    func configure(
        order: OrderListItemEntity,
        highlight: Bool,
        showsTimer: Bool,
        actionTitle: String?,
        actionHandler: (() -> Void)?
    ) {
        orderCodeLabel.text = "주문번호 \(order.orderCode)"
        storeNameLabel.text = order.store.name
        priceLabel.text = "\(order.totalPrice.formattedWithSeparator)원"
        statusLabel.text = order.currentOrderStatus.description
        statusLabel.text = statusText(for: order.currentOrderStatus)
        statusLabel.backgroundColor = statusColor(for: order.currentOrderStatus)
        timerStack.isHidden = !showsTimer
        if showsTimer {
            let remaining = remainingMinutes(for: order.createdAt)
            timerLabel.text = "남은 \(remaining)분"
            timerCircleView.update(progress: progressValue(for: order.createdAt))
        }

        if let title = actionTitle {
            actionButton.isHidden = false
            actionButton.setTitle(title, for: .normal)
            self.actionHandler = actionHandler
        } else {
            actionButton.isHidden = true
            self.actionHandler = nil
        }

        containerView.layer.borderColor = highlight ? AppColor.brightForsythia.cgColor : AppColor.gray30.cgColor
        containerView.backgroundColor = highlight ? AppColor.brightForsythia.withAlphaComponent(0.12) : AppColor.gray0
    }

    @objc private func handleAction() {
        actionHandler?()
    }

    private func remainingMinutes(for createdAt: Date?) -> Int {
        guard let createdAt else {
            return AdminOrderTiming.estimatedMinutes
        }
        let minutes = Calendar.current.dateComponents([.minute], from: createdAt, to: Date()).minute ?? 0
        return max(AdminOrderTiming.estimatedMinutes - minutes, 0)
    }

    private func progressValue(for createdAt: Date?) -> CGFloat {
        guard let createdAt else { return 0 }
        let minutes = Calendar.current.dateComponents([.minute], from: createdAt, to: Date()).minute ?? 0
        let progress = CGFloat(minutes) / CGFloat(max(AdminOrderTiming.estimatedMinutes, 1))
        return min(max(progress, 0), 1)
    }

    private func statusText(for status: OrderStatusEntity) -> String {
        if status == .pendingApproval {
            return "접수 대기"
        }
        return status.description
    }

    private func statusColor(for status: OrderStatusEntity) -> UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.brightForsythia
        case .approved, .inProgress:
            return AppColor.deepSprout
        case .readyForPickup:
            return AppColor.blackSprout
        case .pickedUp:
            return AppColor.gray60
        }
    }
}

private final class AdminTimerCircleView: UIView {
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }

    func update(progress: CGFloat) {
        progressLayer.strokeEnd = progress
    }

    private func setupLayers() {
        backgroundLayer.strokeColor = AppColor.gray30.cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = Layout.timerLineWidth

        progressLayer.strokeColor = AppColor.deepSprout.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = Layout.timerLineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    private func updatePath() {
        let inset = Layout.timerLineWidth / 2
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(ovalIn: rect).cgPath
        backgroundLayer.path = path
        progressLayer.path = path
    }
}

private enum Layout {
    static let containerCornerRadius: CGFloat = 16
    static let containerBorderWidth: CGFloat = 1
    static let statusCornerRadius: CGFloat = 10
    static let actionCornerRadius: CGFloat = 12
    static let statusMinWidth: CGFloat = 70
    static let statusHeight: CGFloat = 20
    static let actionHeight: CGFloat = 36
    static let timerSize: CGFloat = 18
    static let timerLineWidth: CGFloat = 2
}
