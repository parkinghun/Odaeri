//
//  AdminOrdersViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

final class AdminOrdersViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let selectOrder: AnyPublisher<OrderListItemEntity, Never>
        let updateStatus: AnyPublisher<OrderStatusEntity, Never>
    }

    struct Output {
        let orders: AnyPublisher<[OrderListItemEntity], Never>
        let selectedOrder: AnyPublisher<OrderListItemEntity?, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let statusUpdated: AnyPublisher<OrderListItemEntity, Never>
    }

    private let service: AdminOrderService
    private let ordersSubject = CurrentValueSubject<[OrderListItemEntity], Never>([])
    private let selectedOrderSubject = CurrentValueSubject<OrderListItemEntity?, Never>(nil)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let statusUpdatedSubject = PassthroughSubject<OrderListItemEntity, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(service: AdminOrderService = AdminOrderService()) {
        self.service = service
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .merge(with: input.refresh)
            .sink { [weak self] in
                self?.fetchOrders()
            }
            .store(in: &cancellables)

        input.selectOrder
            .sink { [weak self] order in
                self?.selectedOrderSubject.send(order)
            }
            .store(in: &cancellables)

        input.updateStatus
            .sink { [weak self] nextStatus in
                self?.updateSelectedOrderStatus(nextStatus)
            }
            .store(in: &cancellables)

        return Output(
            orders: ordersSubject.eraseToAnyPublisher(),
            selectedOrder: selectedOrderSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            statusUpdated: statusUpdatedSubject.eraseToAnyPublisher()
        )
    }
}

private extension AdminOrdersViewModel {
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
                    let sortedOrders = orders.sorted {
                        let left = $0.createdAt ?? .distantPast
                        let right = $1.createdAt ?? .distantPast
                        return left > right
                    }
                    self?.ordersSubject.send(sortedOrders)
                    if self?.selectedOrderSubject.value == nil {
                        self?.selectedOrderSubject.send(sortedOrders.first)
                    }
                }
            )
            .store(in: &cancellables)
    }

    func updateSelectedOrderStatus(_ nextStatus: OrderStatusEntity) {
        guard let selected = selectedOrderSubject.value else { return }
        service.updateOrderStatus(orderCode: selected.orderCode, nextStatus: nextStatus)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] in
                    guard let self else { return }
                    let updated = self.updateOrder(selected, with: nextStatus)
                    self.selectedOrderSubject.send(updated)
                    self.statusUpdatedSubject.send(updated)
                }
            )
            .store(in: &cancellables)
    }

    func updateOrder(_ order: OrderListItemEntity, with status: OrderStatusEntity) -> OrderListItemEntity {
        OrderListItemEntity(copying: order, status: status)
    }
}

private extension OrderListItemEntity {
    init(copying order: OrderListItemEntity, status: OrderStatusEntity) {
        self.orderId = order.orderId
        self.orderCode = order.orderCode
        self.totalPrice = order.totalPrice
        self.review = order.review
        self.store = order.store
        self.orderMenuList = order.orderMenuList
        self.currentOrderStatus = status
        self.orderStatusTimeline = order.orderStatusTimeline
        self.paidAt = order.paidAt
        self.createdAt = order.createdAt
        self.updatedAt = Date()
    }
}
