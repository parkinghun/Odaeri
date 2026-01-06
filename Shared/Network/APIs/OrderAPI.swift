//
//  OrderAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum OrderAPI {
    case createOrder(request: OrderCreateRequest)
    case getOrderList
    case updateOrderStatus(orderCode: String, nextStatus: OrderStatusUpdateRequest)
}

extension OrderAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createOrder, .getOrderList:
            return "/orders"
        case let .updateOrderStatus(orderCode, _):
            return "/orders/\(orderCode)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createOrder:
            return .post
        case .getOrderList:
            return .get
        case .updateOrderStatus:
            return .put
        }
    }

    var task: Task {
        switch self {
        case let .createOrder(request):
            return .requestCustomJSONEncodable(request, encoder: .init())
        case .getOrderList:
            return .requestPlain
        case let .updateOrderStatus(_, nextStatus):
            return .requestParameters(
                parameters: ["nextStatus": nextStatus.nextStatus],
                encoding: JSONEncoding.default
            )
        }
    }
}
