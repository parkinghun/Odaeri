//
//  AdminOrderService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya

final class AdminOrderService: AdminOrderProviding {
    private let provider: MoyaProvider<OrderAPI>

    init(provider: MoyaProvider<OrderAPI> = ProviderFactory.makeOrderProvider()) {
        self.provider = provider
    }

    func fetchOrders() -> AnyPublisher<[OrderListItemEntity], NetworkError> {
        provider.requestPublisher(.getOrderList)
            .map { (response: OrderListResponse) in
                response.data.map { OrderListItemEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func updateOrderStatus(orderCode: String, nextStatus: OrderStatusEntity) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.updateOrderStatus(orderCode: orderCode, nextStatus: .init(status: nextStatus)))
            .map { (_: MessageResponse) in
                ()
            }
            .eraseToAnyPublisher()
    }
}
