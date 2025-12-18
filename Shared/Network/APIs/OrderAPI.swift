//
//  OrderAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum OrderAPI {
    case createOrder(storeId: Int, menuId: Int, quantity: Int, pickupTime: String)
    case getOrderList(status: String?)
    case getOrderDetail(orderId: Int)
    case cancelOrder(orderId: Int, reason: String)
    case confirmPickup(orderId: Int)
    case getOrderHistory(page: Int, limit: Int)
    case reorder(orderId: Int)
}

extension OrderAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createOrder:
            return "/orders"
        case .getOrderList:
            return "/orders"
        case .getOrderDetail(let orderId):
            return "/orders/\(orderId)"
        case .cancelOrder(let orderId, _):
            return "/orders/\(orderId)/cancel"
        case .confirmPickup(let orderId):
            return "/orders/\(orderId)/pickup"
        case .getOrderHistory:
            return "/orders/history"
        case .reorder(let orderId):
            return "/orders/\(orderId)/reorder"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createOrder, .reorder:
            return .post
        case .getOrderList, .getOrderDetail, .getOrderHistory:
            return .get
        case .cancelOrder, .confirmPickup:
            return .patch
        }
    }

    var task: Task {
        switch self {
        case let .createOrder(storeId, menuId, quantity, pickupTime):
            return .requestParameters(
                parameters: [
                    "storeId": storeId,
                    "menuId": menuId,
                    "quantity": quantity,
                    "pickupTime": pickupTime
                ],
                encoding: JSONEncoding.default
            )

        case let .getOrderList(status):
            if let status = status {
                return .requestParameters(
                    parameters: ["status": status],
                    encoding: URLEncoding.queryString
                )
            }
            return .requestPlain

        case .getOrderDetail:
            return .requestPlain

        case let .cancelOrder(_, reason):
            return .requestParameters(
                parameters: ["reason": reason],
                encoding: JSONEncoding.default
            )

        case .confirmPickup:
            return .requestPlain

        case let .getOrderHistory(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case .reorder:
            return .requestPlain
        }
    }
}
