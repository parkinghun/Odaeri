//
//  OrderRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation
import Combine
import Moya

final class OrderRepositoryImpl: OrderRepository {
    private let provider = MoyaProvider<OrderAPI>()

    func createOrder(storeId: String, orderMenuList: [OrderMenuItem], totalPrice: Int) -> AnyPublisher<OrderCreateEntity, NetworkError> {
        let request = OrderCreateRequest(
            storeId: storeId,
            orderMenuList: orderMenuList,
            totalPrice: totalPrice
        )

        return provider.requestPublisher(.createOrder(request: request))
            .map { (response: OrderCreateResponse) in
                OrderCreateEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func getOrderList(status: String?) -> AnyPublisher<[OrderListItemEntity], NetworkError> {
        provider.requestPublisher(.getOrderList)
            .map { (response: OrderListResponse) in
                response.data.map { OrderListItemEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }
}
