//
//  OrderCurrentStatusCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class OrderCurrentStatusCell: BaseCollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.brightSprout.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let orderCodeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문번호"
        label.font = AppFont.brandCaption1
        label.textColor = AppColor.gray45
        return label
    }()

    private let orderCodeValueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.brandCaption1
        label.textColor = AppColor.gray60
        return label
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.brandBody1
        label.textColor = AppColor.blackSprout
        return label
    }()

    private let orderDateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2SemiBold
        label.textColor = AppColor.brightSprout
        return label
    }()
    
    private let categoryImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = AppColor.gray45
        return view
    }()

    private lazy var orderCodeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [orderCodeTitleLabel, orderCodeValueLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .center
        return stackView
    }()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [orderCodeStackView, storeNameLabel, orderDateLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .leading
        return stackView
    }()

    private let statusContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let statusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .leading
        return stackView
    }()

    override func setupUI() {
        super.setupUI()
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)

        containerView.addSubview(infoStackView)
        containerView.addSubview(categoryImageView)
        containerView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusStackView)

        orderCodeTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        orderCodeTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        infoStackView.setCustomSpacing(AppSpacing.medium, after: orderCodeStackView)
        infoStackView.setCustomSpacing(AppSpacing.xSmall, after: storeNameLabel)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.trailing.lessThanOrEqualTo(statusContainerView.snp.leading).offset(-AppSpacing.small)
        }

        categoryImageView.snp.makeConstraints {
            $0.top.equalTo(infoStackView.snp.bottom).offset(AppSpacing.medium)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.size.equalTo(100)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppSpacing.screenMargin)
        }

        statusContainerView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.trailing.equalToSuperview().inset(AppSpacing.large)
        }

        statusStackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.horizontalEdges.equalToSuperview().inset(18)
        }

        statusContainerView.setContentHuggingPriority(.required, for: .horizontal)
        statusContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configure(with order: OrderListItemEntity) {
        orderCodeValueLabel.text = order.orderCode
        storeNameLabel.text = order.store.name
        orderDateLabel.text = formattedTime(order: order)
        categoryImageView.image = categoryImage(for: order.store.category)

        statusStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let statuses: [OrderStatusEntity] = [
            .pendingApproval, .approved, .inProgress, .readyForPickup, .pickedUp
        ]
        for (index, status) in statuses.enumerated() {
            let isActive = isActiveStatus(status: status, order: order)
            let timeText = statusTimeText(for: status, order: order)
            let showsConnector = index < statuses.count - 1
            let isConnectorActive = isConnectorActive(at: index, order: order, statuses: statuses)
            let row = OrderStatusStepView(
                status: status.description,
                timeText: timeText,
                isActive: isActive,
                showsConnector: showsConnector,
                isConnectorActive: isConnectorActive
            )
            statusStackView.addArrangedSubview(row)
        }
    }

    private func formattedTime(order: OrderListItemEntity) -> String {
        if let createdAt = order.createdAt {
            return DateFormatter.fullDisplay.string(from: createdAt)
        }
        return "주문 시간 미확인"
    }

    private func categoryImage(for category: String) -> UIImage? {
        switch category.lowercased() {
        case "bakery":
            return Category.bakery.image
        case "coffee":
            return Category.coffee.image
        case "dessert":
            return Category.dessert.image
        case "fastfood":
            return Category.fastFood.image
        default:
            return Category.more.image
        }
    }

    private func isActiveStatus(status: OrderStatusEntity, order: OrderListItemEntity) -> Bool {
        let orderList: [OrderStatusEntity] = [.pendingApproval, .approved, .inProgress, .readyForPickup, .pickedUp]
        guard let currentIndex = orderList.firstIndex(of: order.currentOrderStatus),
              let statusIndex = orderList.firstIndex(of: status) else {
            return false
        }
        return statusIndex <= currentIndex
    }

    private func isConnectorActive(at index: Int, order: OrderListItemEntity, statuses: [OrderStatusEntity]) -> Bool {
        let orderList: [OrderStatusEntity] = statuses
        guard let currentIndex = orderList.firstIndex(of: order.currentOrderStatus) else { return false }
        return index < currentIndex
    }

    private func statusTimeText(for status: OrderStatusEntity, order: OrderListItemEntity) -> String? {
        guard let timeline = order.orderStatusTimeline.first(where: { $0.status == status }),
              timeline.completed,
              let changedAt = timeline.changedAt else {
            return nil
        }
        return DateFormatter.timeDisplay.string(from: changedAt)
    }
}

private final class OrderStatusStepView: UIView {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2SemiBold
        label.textColor = AppColor.gray60
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2Medium
        label.textColor = AppColor.gray60
        label.isHidden = true
        return label
    }()

    private let connectorView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 2
        return view
    }()

    init(
        status: String,
        timeText: String?,
        isActive: Bool,
        showsConnector: Bool,
        isConnectorActive: Bool
    ) {
        super.init(frame: .zero)
        setupUI()
        configure(
            status: status,
            timeText: timeText,
            isActive: isActive,
            showsConnector: showsConnector,
            isConnectorActive: isConnectorActive
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(connectorView)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(AppSpacing.xSmall)
            $0.centerY.equalTo(iconView)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(AppSpacing.xSmall)
            $0.centerY.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualToSuperview()
        }

        connectorView.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom)
            $0.centerX.equalTo(iconView)
            $0.width.equalTo(4)
            $0.height.equalTo(AppSpacing.xLarge)
            $0.bottom.equalToSuperview()
        }
    }

    private func configure(
        status: String,
        timeText: String?,
        isActive: Bool,
        showsConnector: Bool,
        isConnectorActive: Bool
    ) {
        let iconImage = (isActive ? AppImage.progressFinish : AppImage.progressDefault)
            .resize(to: CGSize(width: 16, height: 16))
            .withTintColor(isActive ? AppColor.blackSprout : AppColor.gray45)
        iconView.image = iconImage
        titleLabel.text = status
        titleLabel.textColor = isActive ? AppColor.gray90 : AppColor.gray45
        if let timeText {
            timeLabel.isHidden = false
            timeLabel.text = timeText
        } else {
            timeLabel.isHidden = true
            timeLabel.text = nil
        }
        connectorView.isHidden = !showsConnector
        connectorView.backgroundColor = isConnectorActive ? AppColor.blackSprout : AppColor.gray30
    }
}
