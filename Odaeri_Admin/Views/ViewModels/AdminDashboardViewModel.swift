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
        let orderLookupOrders: AnyPublisher<[OrderListItemEntity], Never>
        let salesOrders: AnyPublisher<[OrderListItemEntity], Never>
        let selectedOrder: AnyPublisher<OrderListItemEntity?, Never>
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
    private let orderLookupOrdersSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let selectedOrderSubject = CurrentValueSubject<OrderListItemEntity?, Never>(nil)
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
            orderLookupOrders: orderLookupOrdersSubject.eraseToAnyPublisher(),
            salesOrders: ordersSubject.eraseToAnyPublisher(),
            selectedOrder: selectedOrderSubject.eraseToAnyPublisher(),
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
        let lookupOrders = sortOrders(orders, by: .latest)

        inProgressNewSubject.send(sortOrders(newOrders, by: .latest))
        inProgressActiveSubject.send(sortOrders(activeOrders, by: inProgressSortOrder))
        completedOrdersSubject.send(sortOrders(completedOrders, by: completedSortOrder))
        orderLookupOrdersSubject.send(lookupOrders)

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
            AdminSideTabBarItem(tab: .orderLookup, title: "주문조회", count: nil, iconName: "doc.text.magnifyingglass"),
            AdminSideTabBarItem(tab: .sales, title: "매출조회", count: nil, iconName: "chart.bar.fill"),
            AdminSideTabBarItem(tab: .storeManagement, title: "가게관리", count: nil, iconName: "storefront.fill")
        ]
    }

    func updateSelectedOrderForTab(_ tab: AdminDashboardTab) {
        switch tab {
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
        case .orderLookup:
            selectedOrderSubject.send(orderLookupOrdersSubject.value.first)
        case .sales:
            selectedOrderSubject.send(nil)
        case .storeManagement:
            selectedOrderSubject.send(nil)
        }
    }

}
