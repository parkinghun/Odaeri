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
        view.layer.borderColor = AppColor.gray30.cgColor
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
        label.textColor = AppColor.gray60
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
        stackView.spacing = AppSpacing.small
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

        infoStackView.setCustomSpacing(AppSpacing.small, after: orderCodeStackView)
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
            $0.size.equalTo(120)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppSpacing.screenMargin)
        }

        statusContainerView.snp.makeConstraints {
            $0.width.equalTo(140)
            $0.height.equalTo(200)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(17)
        }

        statusStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        statusContainerView.setContentHuggingPriority(.required, for: .horizontal)
        statusContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configure(with display: OrderCurrentStatusDisplay) {
        orderCodeTitleLabel.text = display.orderCodeTitle
        orderCodeValueLabel.text = display.orderCodeValue
        storeNameLabel.text = display.storeName
        orderDateLabel.text = display.orderDateText
        categoryImageView.image = display.categoryImage

        statusStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for step in display.statusSteps {
            let row = OrderStatusStepView(display: step)
            statusStackView.addArrangedSubview(row)
        }
    }
}

private final class OrderStatusStepView: UIView {
    private let iconColumnStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .center
        return stackView
    }()

    private let textRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .center
        return stackView
    }()

    private let rowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .top
        return stackView
    }()

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

    init(display: OrderStatusStepDisplay) {
        super.init(frame: .zero)
        setupUI()
        configure(display: display)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(rowStackView)
        rowStackView.addArrangedSubview(iconColumnStackView)
        rowStackView.addArrangedSubview(textRowStackView)

        iconColumnStackView.addArrangedSubview(iconView)
        iconColumnStackView.addArrangedSubview(connectorView)

        textRowStackView.addArrangedSubview(titleLabel)
        textRowStackView.addArrangedSubview(timeLabel)

        rowStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints {
            $0.size.equalTo(16)
        }

        connectorView.snp.makeConstraints {
            $0.width.equalTo(4)
            $0.height.equalTo(AppSpacing.xLarge)
        }
    }

    private func configure(display: OrderStatusStepDisplay) {
        let iconImage = (display.isActive ? AppImage.progressFinish : AppImage.progressDefault)
            .resize(to: CGSize(width: 16, height: 16))
            .withTintColor(display.isActive ? AppColor.blackSprout : AppColor.gray45)
        iconView.image = iconImage
        titleLabel.text = display.title
        titleLabel.textColor = display.isActive ? AppColor.gray90 : AppColor.gray45
        if let timeText = display.timeText {
            timeLabel.isHidden = false
            timeLabel.text = timeText
        } else {
            timeLabel.isHidden = true
            timeLabel.text = nil
        }
        connectorView.isHidden = !display.showsConnector
        connectorView.backgroundColor = display.isConnectorActive ? AppColor.blackSprout : AppColor.gray30
    }
}
