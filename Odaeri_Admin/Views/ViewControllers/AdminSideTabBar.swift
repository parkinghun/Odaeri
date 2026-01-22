//
//  AdminSideTabBar.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminSideTabBar: UIViewController {
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let selectionSubject = PassthroughSubject<AdminDashboardTab, Never>()
    private let settingsSubject = PassthroughSubject<Void, Never>()
    private var items: [AdminSideTabBarItem] = []
    private var selectedTab: AdminDashboardTab = .inProgress
    private var tabViews: [AdminSideTabBarItemView] = []

    var viewDidLoadPublisher: AnyPublisher<Void, Never> {
        viewDidLoadSubject.eraseToAnyPublisher()
    }

    var selectionPublisher: AnyPublisher<AdminDashboardTab, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    var settingsPublisher: AnyPublisher<Void, Never> {
        settingsSubject.eraseToAnyPublisher()
    }

    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = AppColor.gray45
        return button
    }()

    private let tabStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = Layout.tabSpacing
        return stack
    }()
    private let bottomMenuView = AdminSideTabBarBottomMenuView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewDidLoadSubject.send(())
    }

    private func setupUI() {
        view.backgroundColor = AppColor.adminDark

        view.addSubview(menuButton)
        view.addSubview(tabStackView)
        view.addSubview(bottomMenuView)

        menuButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(Layout.headerTopInset)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.menuButtonHeight)
        }

        tabStackView.snp.makeConstraints {
            $0.top.equalTo(menuButton.snp.bottom).offset(Layout.sectionSpacing)
            $0.leading.trailing.equalToSuperview()
        }

        bottomMenuView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.bottomInset)
        }

        bottomMenuView.onSettingsTap = { [weak self] in
            self?.settingsSubject.send(())
        }
    }

    func updateItems(_ items: [AdminSideTabBarItem]) {
        self.items = items
        reloadTabs()
    }

    func updateSelection(_ tab: AdminDashboardTab) {
        selectedTab = tab
        updateTabSelection()
    }

    private func reloadTabs() {
        tabViews.forEach { $0.removeFromSuperview() }
        tabViews = items.map { item in
            let tabView = AdminSideTabBarItemView()
            tabView.configure(item: item, isSelected: item.tab == selectedTab)
            tabView.addTarget(self, action: #selector(handleTabTap(_:)), for: .touchUpInside)
            return tabView
        }
        tabViews.forEach { tabStackView.addArrangedSubview($0) }
    }

    private func updateTabSelection() {
        tabViews.forEach { tabView in
            tabView.updateSelection(isSelected: tabView.tab == selectedTab)
        }
    }

    @objc private func handleTabTap(_ sender: AdminSideTabBarItemView) {
        selectedTab = sender.tab
        selectionSubject.send(sender.tab)
        updateTabSelection()
    }
}

private final class AdminSideTabBarItemView: UIControl {
    private let indicatorView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let contentStackView = UIStackView()

    private(set) var tab: AdminDashboardTab = .inProgress

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.adminDark
        layer.cornerRadius = Layout.itemCornerRadius

        indicatorView.backgroundColor = AppColor.gray0
        indicatorView.isHidden = true
        addSubview(indicatorView)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AppColor.gray75
        iconView.isUserInteractionEnabled = false

        titleLabel.font = AppFont.body2Bold
        titleLabel.textColor = AppColor.gray15
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false

        countLabel.font = AppFont.caption1
        countLabel.textColor = AppColor.gray45
        countLabel.textAlignment = .center
        countLabel.isUserInteractionEnabled = false

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = Layout.itemSpacing
        contentStackView.isUserInteractionEnabled = false

        contentStackView.addArrangedSubview(iconView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(countLabel)

        addSubview(contentStackView)

        indicatorView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.width.equalTo(Layout.indicatorWidth)
            $0.top.bottom.equalToSuperview().inset(Layout.indicatorVerticalInset)
        }

        iconView.snp.makeConstraints {
            $0.width.height.equalTo(Layout.iconSize)
        }

        contentStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.itemHorizontalInset)
            $0.top.bottom.equalToSuperview().inset(Layout.itemVerticalInset)
        }
    }

    func configure(item: AdminSideTabBarItem, isSelected: Bool) {
        tab = item.tab
        iconView.image = UIImage(systemName: item.iconName)
        titleLabel.text = item.title
        applyCount(item.count)
        updateSelection(isSelected: isSelected)
    }

    func updateSelection(isSelected: Bool) {
        indicatorView.isHidden = !isSelected
        backgroundColor = isSelected ? AppColor.adminDarkSelected : AppColor.adminDark
        iconView.tintColor = isSelected ? AppColor.gray0 : AppColor.gray75
        titleLabel.textColor = isSelected ? AppColor.gray0 : AppColor.gray15
    }

    private func applyCount(_ count: Int?) {
        guard let count, count > 0 else {
            countLabel.isHidden = true
            return
        }
        countLabel.isHidden = false
        countLabel.text = "\(count)건"
    }
}


private final class AdminSideTabBarBottomMenuView: UIView {
    private let settingsButton = UIButton(type: .system)
    var onSettingsTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let gearImage = UIImage(systemName: "gearshape.fill")
        settingsButton.setImage(gearImage, for: .normal)
        settingsButton.setTitle("설정", for: .normal)
        settingsButton.tintColor = AppColor.gray30
        settingsButton.setTitleColor(AppColor.gray30, for: .normal)
        settingsButton.titleLabel?.font = AppFont.body3Bold
        settingsButton.semanticContentAttribute = .forceLeftToRight
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        settingsButton.addTarget(self, action: #selector(handleSettingsTap), for: .touchUpInside)

        addSubview(settingsButton)
        settingsButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    @objc private func handleSettingsTap() {
        onSettingsTap?()
    }
}

private enum Layout {
    static let headerTopInset: CGFloat = 8
    static let horizontalInset: CGFloat = 8
    static let sectionSpacing: CGFloat = 20
    static let tabSpacing: CGFloat = 8
    static let bottomInset: CGFloat = 8

    static let menuButtonHeight: CGFloat = 32
    static let itemCornerRadius: CGFloat = 12
    static let itemSpacing: CGFloat = 6
    static let itemHorizontalInset: CGFloat = 4
    static let itemVerticalInset: CGFloat = 10
    static let iconSize: CGFloat = 22
    static let indicatorWidth: CGFloat = 3
    static let indicatorVerticalInset: CGFloat = 6
}
