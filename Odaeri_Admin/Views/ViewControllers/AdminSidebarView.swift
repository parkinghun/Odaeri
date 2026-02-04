//
//  AdminSidebarView.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit

enum AdminSidebarItem: CaseIterable {
    case inProgress
    case completed
    case sales
    case storeManagement
    case settings

    var title: String {
        switch self {
        case .inProgress: return "처리 중"
        case .completed: return "완료"
        case .sales: return "매출 조회"
        case .storeManagement: return "가게 관리"
        case .settings: return "설정"
        }
    }

    var iconName: String {
        switch self {
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle"
        case .sales: return "chart.bar"
        case .storeManagement: return "storefront"
        case .settings: return "gearshape"
        }
    }
}

final class AdminSidebarView: UIView {
    var onSelectItem: ((AdminSidebarItem) -> Void)?

    private let headerView = UIView()
    private let brandLabel = UILabel()
    private let branchLabel = UILabel()

    private let navStack = UIStackView()
    private let footerStack = UIStackView()

    private var itemButtons: [AdminSidebarItem: AdminSidebarButton] = [:]

    private var selectedItem: AdminSidebarItem = .inProgress {
        didSet { updateSelection() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
        updateSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.adminDark

        brandLabel.text = "Odaeri Admin"
        brandLabel.font = AppFont.title1
        brandLabel.textColor = AppColor.gray0

        branchLabel.text = "Gangnam Branch"
        branchLabel.font = AppFont.body3
        branchLabel.textColor = AppColor.gray60

        navStack.axis = .vertical
        navStack.spacing = 8

        footerStack.axis = .vertical
        footerStack.spacing = 8

        AdminSidebarItem.allCases.forEach { item in
            let button = AdminSidebarButton(item: item)
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            itemButtons[item] = button
            if item == .settings {
                footerStack.addArrangedSubview(button)
            } else {
                navStack.addArrangedSubview(button)
            }
        }

        addSubview(headerView)
        headerView.addSubview(brandLabel)
        headerView.addSubview(branchLabel)
        addSubview(navStack)
        addSubview(footerStack)
    }

    private func setupLayout() {
        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        brandLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        branchLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        navStack.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        footerStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func updateSelection() {
        itemButtons.forEach { item, button in
            button.isSelected = (item == selectedItem)
        }
    }

    func updateInProgressCount(_ count: Int) {
        itemButtons[.inProgress]?.setCount(count)
    }

    @objc private func handleTap(_ sender: AdminSidebarButton) {
        let item = sender.item
        selectedItem = item
        onSelectItem?(item)
    }
}

private final class AdminSidebarButton: UIControl {
    let item: AdminSidebarItem

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let selectionIndicator = UIView()

    override var isSelected: Bool {
        didSet { updateStyle() }
    }

    init(item: AdminSidebarItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 10
        backgroundColor = .clear

        selectionIndicator.backgroundColor = AppColor.brightForsythia
        selectionIndicator.layer.cornerRadius = 2

        iconView.image = UIImage(systemName: item.iconName)
        iconView.tintColor = AppColor.gray60
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = item.title
        titleLabel.font = AppFont.body1
        titleLabel.textColor = AppColor.gray60

        countLabel.font = AppFont.caption1
        countLabel.textColor = AppColor.gray60
        countLabel.textAlignment = .right
        countLabel.isHidden = item != .inProgress

        addSubview(selectionIndicator)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(countLabel)

        selectionIndicator.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(3)
            $0.height.equalTo(20)
        }

        iconView.snp.makeConstraints {
            $0.leading.equalTo(selectionIndicator.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(10)
            $0.trailing.lessThanOrEqualTo(countLabel.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }

        snp.makeConstraints { $0.height.equalTo(44) }
    }

    private func updateStyle() {
        if isSelected {
            backgroundColor = AppColor.gray90.withAlphaComponent(0.25)
            iconView.tintColor = AppColor.gray0
            titleLabel.textColor = AppColor.gray0
            countLabel.textColor = AppColor.gray0
            selectionIndicator.isHidden = false
        } else {
            backgroundColor = .clear
            iconView.tintColor = AppColor.gray60
            titleLabel.textColor = AppColor.gray60
            countLabel.textColor = AppColor.gray60
            selectionIndicator.isHidden = true
        }
    }

    func setCount(_ count: Int) {
        guard item == .inProgress else { return }
        countLabel.text = "\(count)건"
        countLabel.isHidden = false
    }
}
