//
//  AdminAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum AdminAPI {
    case adminLogin(email: String, password: String)

    case getOrders(status: String?, page: Int, limit: Int)
    case updateOrderStatus(orderId: Int, status: String)

    case createMenu(storeId: Int, name: String, price: Int, description: String, category: String, imageURL: String)
    case updateMenu(menuId: Int, name: String?, price: Int?, description: String?, isAvailable: Bool?)
    case deleteMenu(menuId: Int)

    case getStoreInfo(storeId: Int)
    case updateStoreInfo(storeId: Int, name: String?, description: String?, isOpen: Bool?)

    case getStatistics(storeId: Int, startDate: String, endDate: String)
}

extension AdminAPI: BaseAPI {
    var path: String {
        switch self {
        case .adminLogin:
            return "/admin/login"

        case .getOrders:
            return "/admin/orders"
        case .updateOrderStatus(let orderId, _):
            return "/admin/orders/\(orderId)/status"

        case .createMenu(let storeId, _, _, _, _, _):
            return "/admin/stores/\(storeId)/menus"
        case .updateMenu(let menuId, _, _, _, _):
            return "/admin/menus/\(menuId)"
        case .deleteMenu(let menuId):
            return "/admin/menus/\(menuId)"

        case .getStoreInfo(let storeId):
            return "/admin/stores/\(storeId)"
        case .updateStoreInfo(let storeId, _, _, _):
            return "/admin/stores/\(storeId)"

        case .getStatistics(let storeId, _, _):
            return "/admin/stores/\(storeId)/statistics"
        }
    }

    var method: Moya.Method {
        switch self {
        case .adminLogin, .createMenu:
            return .post
        case .getOrders, .getStoreInfo, .getStatistics:
            return .get
        case .updateOrderStatus, .updateMenu, .updateStoreInfo:
            return .patch
        case .deleteMenu:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .adminLogin(email, password):
            return .requestParameters(
                parameters: ["email": email, "password": password],
                encoding: JSONEncoding.default
            )

        case let .getOrders(status, page, limit):
            var parameters: [String: Any] = ["page": page, "limit": limit]
            if let status = status {
                parameters["status"] = status
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )

        case let .updateOrderStatus(_, status):
            return .requestParameters(
                parameters: ["status": status],
                encoding: JSONEncoding.default
            )

        case let .createMenu(_, name, price, description, category, imageURL):
            return .requestParameters(
                parameters: [
                    "name": name,
                    "price": price,
                    "description": description,
                    "category": category,
                    "imageURL": imageURL
                ],
                encoding: JSONEncoding.default
            )

        case let .updateMenu(_, name, price, description, isAvailable):
            var parameters = [String: Any]()
            if let name = name {
                parameters["name"] = name
            }
            if let price = price {
                parameters["price"] = price
            }
            if let description = description {
                parameters["description"] = description
            }
            if let isAvailable = isAvailable {
                parameters["isAvailable"] = isAvailable
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case .deleteMenu:
            return .requestPlain

        case .getStoreInfo:
            return .requestPlain

        case let .updateStoreInfo(_, name, description, isOpen):
            var parameters = [String: Any]()
            if let name = name {
                parameters["name"] = name
            }
            if let description = description {
                parameters["description"] = description
            }
            if let isOpen = isOpen {
                parameters["isOpen"] = isOpen
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case let .getStatistics(_, startDate, endDate):
            return .requestParameters(
                parameters: [
                    "startDate": startDate,
                    "endDate": endDate
                ],
                encoding: URLEncoding.queryString
            )
        }
    }
}
