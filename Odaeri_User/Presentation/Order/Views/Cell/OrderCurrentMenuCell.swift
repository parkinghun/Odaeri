//
//  OrderCurrentMenuCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class OrderCurrentMenuCell: BaseCollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.brightSprout.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        stackView.alignment = .fill
        return stackView
    }()

    private let totalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "결제금액"
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray60
        return label
    }()
    
    private let divider = Divider()

    private let totalQuantityLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .right
        return label
    }()
    
    private let totalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        label.textAlignment = .right
        return label
    }()

    private lazy var totalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [totalQuantityLabel, totalPriceLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    override func setupUI() {
        super.setupUI()
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)

        containerView.addSubview(menuStackView)
        containerView.addSubview(divider)
        containerView.addSubview(totalTitleLabel)
        containerView.addSubview(totalStackView)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        menuStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }
        
        divider.snp.makeConstraints {
            $0.top.equalTo(menuStackView.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        totalTitleLabel.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(AppSpacing.medium)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.bottom.equalToSuperview().inset(AppSpacing.medium)
        }

        totalStackView.snp.makeConstraints {
            $0.centerY.equalTo(totalTitleLabel)
            $0.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }
    }

    func configure(with display: OrderCurrentMenuDisplay) {
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in display.menuRows.enumerated() {
            let row = OrderMenuRowView()
            row.configure(menu: item)
            menuStackView.addArrangedSubview(row)

            if index < display.menuRows.count - 1 {
                let divider = Divider(height: 1, color: AppColor.gray30)
                menuStackView.addArrangedSubview(divider)
            }
        }

        totalQuantityLabel.text = display.totalQuantityText
        totalPriceLabel.text = display.totalPriceText
    }
}

private final class OrderMenuRowView: UIView {
    private let menuImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        return label
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        return label
    }()

    private lazy var priceQuantityStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [priceLabel, quantityLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .leading
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, priceQuantityStackView])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(menuImageView)
        addSubview(textStackView)

        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        menuImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(84)
            $0.height.equalTo(52)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(menuImageView.snp.trailing).offset(AppSpacing.large)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
    }

    func configure(menu: OrderMenuRowDisplay) {
        menuImageView.setImage(url: menu.imageUrl)
        nameLabel.text = menu.name
        priceLabel.text = menu.priceText
        quantityLabel.text = menu.quantityText
    }
}
