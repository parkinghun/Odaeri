//
//  AdminSideTabBarController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminSideTabBarController: UIViewController {
    private let topStatusView = AdminTopStatusView()
    private let sideTabBar = AdminSideTabBar()
    private let dashboardController = AdminDashboardSplitViewController()
    private let viewModel: AdminDashboardViewModel
    private let selectedTabSubject = CurrentValueSubject<AdminDashboardTab, Never>(.inProgress)
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AdminDashboardViewModel = AdminDashboardViewModel()) {
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
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupUI() {
        view.backgroundColor = AppColor.adminDark

        view.addSubview(topStatusView)
        addChild(sideTabBar)
        addChild(dashboardController)
        view.addSubview(sideTabBar.view)
        view.addSubview(dashboardController.view)
        sideTabBar.didMove(toParent: self)
        dashboardController.didMove(toParent: self)

        sideTabBar.view.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.width.equalTo(Layout.tabBarWidth)
        }

        topStatusView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalTo(sideTabBar.view.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(Layout.topStatusHeight)
        }

        dashboardController.view.snp.makeConstraints {
            $0.leading.equalTo(sideTabBar.view.snp.trailing)
            $0.top.equalTo(topStatusView.snp.bottom)
            $0.bottom.trailing.equalToSuperview()
        }
    }

    private func bind() {
        sideTabBar.selectionPublisher
            .sink { [weak self] tab in
                self?.selectedTabSubject.send(tab)
            }
            .store(in: &cancellables)

        let input = AdminDashboardViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            refresh: Empty(completeImmediately: false).eraseToAnyPublisher(),
            selectTab: selectedTabSubject.eraseToAnyPublisher(),
            inProgressSort: dashboardController.inProgressSortPublisher,
            completedSort: dashboardController.completedSortPublisher,
            selectOrder: dashboardController.selectionPublisher,
            updateStatus: dashboardController.statusUpdatePublisher
        )
        let output = viewModel.transform(input: input)

        output.sideTabBarItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.sideTabBar.updateItems(items)
            }
            .store(in: &cancellables)

        output.selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                self?.sideTabBar.updateSelection(tab)
                self?.dashboardController.show(tab: tab)
            }
            .store(in: &cancellables)

        output.inProgressNew
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateInProgressNew(orders)
            }
            .store(in: &cancellables)

        output.inProgressActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateInProgressActive(orders)
            }
            .store(in: &cancellables)

        output.completedOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.dashboardController.updateCompleted(orders)
            }
            .store(in: &cancellables)

        output.selectedOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.dashboardController.updateOrder(order)
            }
            .store(in: &cancellables)

        output.salesSummary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.dashboardController.updateSalesSummary(summary)
            }
            .store(in: &cancellables)

        output.salesCharts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] charts in
                self?.dashboardController.updateSalesCharts(charts)
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.dashboardController.showError(message: message)
            }
            .store(in: &cancellables)
    }
}

private enum Layout {
    static let tabBarWidth: CGFloat = 90
    static let topStatusHeight: CGFloat = 36
}

private final class AdminTopStatusView: UIView {
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.adminDark

        statusDot.layer.cornerRadius = LayoutTopStatus.dotSize / 2
        statusDot.backgroundColor = LayoutTopStatus.openColor

        statusLabel.font = AppFont.body2Bold
        statusLabel.textColor = AppColor.gray15
        statusLabel.text = "영업 중"

        timeLabel.font = AppFont.body2
        timeLabel.textColor = AppColor.gray60
        timeLabel.text = timeText()

        let statusStack = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.spacing = LayoutTopStatus.statusSpacing

        let stack = UIStackView(arrangedSubviews: [statusStack, UIView(), timeLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = LayoutTopStatus.timeSpacing

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(LayoutTopStatus.horizontalInset)
            $0.centerY.equalToSuperview()
        }

        statusDot.snp.makeConstraints {
            $0.width.height.equalTo(LayoutTopStatus.dotSize)
        }
    }

    private func timeText() -> String {
        DateFormatter.adminStatus.string(from: Date())
    }

    func updateStatus(isOpen: Bool) {
        statusDot.backgroundColor = isOpen ? LayoutTopStatus.openColor : LayoutTopStatus.closedColor
        statusLabel.text = isOpen ? "영업 중" : "영업 종료"
    }
}

private enum LayoutTopStatus {
    static let dotSize: CGFloat = 6
    static let statusSpacing: CGFloat = 6
    static let timeSpacing: CGFloat = 12
    static let horizontalInset: CGFloat = 12
    static let openColor = UIColor.systemGreen
    static let closedColor = UIColor.systemRed
}
