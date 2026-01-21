//
//  AdminDashboardViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import Combine

final class AdminDashboardViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let selectTab: AnyPublisher<AdminDashboardTab, Never>
        let inProgressSort: AnyPublisher<AdminSortOrder, Never>
        let completedSort: AnyPublisher<AdminSortOrder, Never>
        let selectOrder: AnyPublisher<OrderListItemEntity?, Never>
        let updateStatus: AnyPublisher<AdminOrderStatusUpdate, Never>
    }

    struct Output {
        let sideTabBarItems: AnyPublisher<[AdminSideTabBarItem], Never>
        let selectedTab: AnyPublisher<AdminDashboardTab, Never>
        let inProgressNew: AnyPublisher<[OrderListItemEntity], Never>
        let inProgressActive: AnyPublisher<[OrderListItemEntity], Never>
        let completedOrders: AnyPublisher<[OrderListItemEntity], Never>
        let selectedOrder: AnyPublisher<OrderListItemEntity?, Never>
        let salesSummary: AnyPublisher<AdminSalesSummary, Never>
        let salesCharts: AnyPublisher<AdminSalesCharts, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    private let service: AdminOrderProviding
    private let ordersSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let sideTabBarItemsSubject = CurrentValueSubject<[AdminSideTabBarItem], Never>([])
    private let selectedTabSubject = CurrentValueSubject<AdminDashboardTab, Never>(.inProgress)
    private let inProgressNewSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let inProgressActiveSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let completedOrdersSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let selectedOrderSubject = CurrentValueSubject<OrderListItemEntity?, Never>(nil)
    private let salesSummarySubject = CurrentValueSubject<AdminSalesSummary, Never>(AdminDashboardViewModel.mockSummary())
    private let salesChartsSubject = CurrentValueSubject<AdminSalesCharts, Never>(AdminDashboardViewModel.mockCharts())
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var inProgressSortOrder: AdminSortOrder = .latest
    private var completedSortOrder: AdminSortOrder = .latest

    init(service: AdminOrderProviding = AdminOrderMockService()) {
        self.service = service
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .merge(with: input.refresh)
            .sink { [weak self] in
                self?.fetchOrders()
            }
            .store(in: &cancellables)

        input.selectTab
            .sink { [weak self] tab in
                self?.selectedTabSubject.send(tab)
                self?.updateSelectedOrderForTab(tab)
            }
            .store(in: &cancellables)

        input.inProgressSort
            .sink { [weak self] order in
                self?.inProgressSortOrder = order
                self?.publishSections()
            }
            .store(in: &cancellables)

        input.completedSort
            .sink { [weak self] order in
                self?.completedSortOrder = order
                self?.publishSections()
            }
            .store(in: &cancellables)

        input.selectOrder
            .sink { [weak self] order in
                self?.selectedOrderSubject.send(order)
            }
            .store(in: &cancellables)

        input.updateStatus
            .sink { [weak self] update in
                self?.updateStatus(update)
            }
            .store(in: &cancellables)

        return Output(
            sideTabBarItems: sideTabBarItemsSubject.eraseToAnyPublisher(),
            selectedTab: selectedTabSubject.eraseToAnyPublisher(),
            inProgressNew: inProgressNewSubject.eraseToAnyPublisher(),
            inProgressActive: inProgressActiveSubject.eraseToAnyPublisher(),
            completedOrders: completedOrdersSubject.eraseToAnyPublisher(),
            selectedOrder: selectedOrderSubject.eraseToAnyPublisher(),
            salesSummary: salesSummarySubject.eraseToAnyPublisher(),
            salesCharts: salesChartsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
}

private extension AdminDashboardViewModel {
    func fetchOrders() {
        isLoadingSubject.send(true)
        service.fetchOrders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] orders in
                    self?.ordersSubject.send(orders)
                    self?.publishSections()
                }
            )
            .store(in: &cancellables)
    }

    func updateStatus(_ update: AdminOrderStatusUpdate) {
        service.updateOrderStatus(orderCode: update.order.orderCode, nextStatus: update.nextStatus)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] in
                    self?.applyLocalStatusUpdate(update)
                }
            )
            .store(in: &cancellables)
    }

    func applyLocalStatusUpdate(_ update: AdminOrderStatusUpdate) {
        let updatedOrders = ordersSubject.value.map { order in
            guard order.orderCode == update.order.orderCode else { return order }
            return order.updatingStatus(update.nextStatus)
        }
        ordersSubject.send(updatedOrders)
        publishSections()
    }

    func publishSections() {
        let orders = ordersSubject.value
        let newOrders = orders.filter { $0.currentOrderStatus == .pendingApproval }
        let activeOrders = orders.filter { isActiveStatus($0.currentOrderStatus) }
        let completedOrders = orders.filter { $0.currentOrderStatus == .pickedUp }

        inProgressNewSubject.send(sortOrders(newOrders, by: .latest))
        inProgressActiveSubject.send(sortOrders(activeOrders, by: inProgressSortOrder))
        completedOrdersSubject.send(sortOrders(completedOrders, by: completedSortOrder))

        updateSelectedOrderForTab(selectedTabSubject.value)

        sideTabBarItemsSubject.send(makeSideTabBarItems(newCount: newOrders.count + activeOrders.count))
    }

    func sortOrders(_ orders: [OrderListItemEntity], by order: AdminSortOrder) -> [OrderListItemEntity] {
        let sorted = orders.sorted { left, right in
            let leftDate = left.createdAt ?? .distantPast
            let rightDate = right.createdAt ?? .distantPast
            return order == .latest ? leftDate > rightDate : leftDate < rightDate
        }
        return sorted
    }

    func isActiveStatus(_ status: OrderStatusEntity) -> Bool {
        switch status {
        case .approved, .inProgress, .readyForPickup:
            return true
        case .pendingApproval, .pickedUp:
            return false
        }
    }

    func makeSideTabBarItems(newCount: Int) -> [AdminSideTabBarItem] {
        [
            AdminSideTabBarItem(tab: .inProgress, title: "처리중", count: newCount, iconName: "clock.fill"),
            AdminSideTabBarItem(tab: .completed, title: "완료", count: nil, iconName: "checkmark.circle.fill"),
            AdminSideTabBarItem(tab: .sales, title: "매출조회", count: nil, iconName: "chart.bar.fill")
        ]
    }

    func updateSelectedOrderForTab(_ tab: AdminDashboardTab) {
        switch tab {
        case .sales:
            selectedOrderSubject.send(nil)
        case .completed:
            if selectedOrderSubject.value == nil || selectedOrderSubject.value?.currentOrderStatus != .pickedUp {
                selectedOrderSubject.send(completedOrdersSubject.value.first)
            }
        case .inProgress:
            if let selected = selectedOrderSubject.value,
               selected.currentOrderStatus != .pickedUp {
                return
            }
            let candidate = inProgressNewSubject.value.first ?? inProgressActiveSubject.value.first
            selectedOrderSubject.send(candidate)
        }
    }

    static func mockSummary() -> AdminSalesSummary {
        AdminSalesSummary(
            todayRevenue: MockValue.todayRevenue,
            averageOrderValue: MockValue.averageOrderValue,
            cancelRate: MockValue.cancelRate,
            insight: MockValue.insight
        )
    }

    static func mockCharts() -> AdminSalesCharts {
        let hourlySales = [
            AdminSalesPoint(label: "10시", value: MockValue.hourlySales[0]),
            AdminSalesPoint(label: "12시", value: MockValue.hourlySales[1]),
            AdminSalesPoint(label: "14시", value: MockValue.hourlySales[2]),
            AdminSalesPoint(label: "16시", value: MockValue.hourlySales[3]),
            AdminSalesPoint(label: "18시", value: MockValue.hourlySales[4]),
            AdminSalesPoint(label: "20시", value: MockValue.hourlySales[5])
        ]

        let topMenus = [
            AdminSalesPoint(label: "카페 라떼", value: MockValue.topMenuSales[0]),
            AdminSalesPoint(label: "아메리카노", value: MockValue.topMenuSales[1]),
            AdminSalesPoint(label: "치즈케이크", value: MockValue.topMenuSales[2]),
            AdminSalesPoint(label: "바닐라 라떼", value: MockValue.topMenuSales[3]),
            AdminSalesPoint(label: "스콘", value: MockValue.topMenuSales[4])
        ]

        let weeklyTrend = [
            AdminSalesPoint(label: "월", value: MockValue.weeklyTrend[0]),
            AdminSalesPoint(label: "화", value: MockValue.weeklyTrend[1]),
            AdminSalesPoint(label: "수", value: MockValue.weeklyTrend[2]),
            AdminSalesPoint(label: "목", value: MockValue.weeklyTrend[3]),
            AdminSalesPoint(label: "금", value: MockValue.weeklyTrend[4]),
            AdminSalesPoint(label: "토", value: MockValue.weeklyTrend[5]),
            AdminSalesPoint(label: "일", value: MockValue.weeklyTrend[6])
        ]

        return AdminSalesCharts(
            hourlySales: hourlySales,
            topMenus: topMenus,
            weeklyTrend: weeklyTrend
        )
    }
}

private enum MockValue {
    static let todayRevenue = 384000
    static let averageOrderValue = 12800
    static let cancelRate = 2.3
    static let insight = "지난주 대비 매출이 15% 상승했습니다."
    static let hourlySales: [Double] = [45, 80, 60, 72, 95, 55]
    static let topMenuSales: [Double] = [120, 96, 88, 74, 63]
    static let weeklyTrend: [Double] = [320, 360, 410, 390, 460, 520, 480]
}
