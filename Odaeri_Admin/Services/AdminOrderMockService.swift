//
//  AdminOrderMockService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import Combine

final class AdminOrderMockService: AdminOrderProviding {
    private var orders: [OrderListItemEntity]

    init(orders: [OrderListItemEntity] = AdminOrderMockFactory.makeOrders()) {
        self.orders = orders
    }

    func fetchOrders() -> AnyPublisher<[OrderListItemEntity], NetworkError> {
        Just(orders)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }

    func updateOrderStatus(orderCode: String, nextStatus: OrderStatusEntity) -> AnyPublisher<Void, NetworkError> {
        if let index = orders.firstIndex(where: { $0.orderCode == orderCode }) {
            orders[index] = orders[index].updatingStatus(nextStatus)
        }

        return Just(())
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}
