//
//  OrderRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation
import Combine

protocol OrderRepository {
    func createOrder(storeId: String, orderMenuList: [OrderMenuItem], totalPrice: Int) -> AnyPublisher<OrderCreateEntity, NetworkError>
    func getOrderList(status: String?) -> AnyPublisher<[OrderListItemEntity], NetworkError>
}
