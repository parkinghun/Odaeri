//
//  AdminOrderProviding.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import Combine

protocol AdminOrderProviding {
    func fetchOrders() -> AnyPublisher<[OrderListItemEntity], NetworkError>
    func updateOrderStatus(orderCode: String, nextStatus: OrderStatusEntity) -> AnyPublisher<Void, NetworkError>
}

