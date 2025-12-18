//
//  StoreAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum StoreAPI {
    case getStoreList(category: String?, latitude: Double?, longitude: Double?)
    case getStoreDetail(storeId: Int)
    case searchStore(keyword: String, page: Int)
    case getPopularStores(limit: Int)
    case getNearbyStores(latitude: Double, longitude: Double, radius: Int)
    case getMenuList(storeId: Int, category: String?)
    case getMenuDetail(menuId: Int)
}

extension StoreAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .getStoreList:
            return "/stores"
        case .getStoreDetail(let storeId):
            return "/stores/\(storeId)"
        case .searchStore:
            return "/stores/search"
        case .getPopularStores:
            return "/stores/popular"
        case .getNearbyStores:
            return "/stores/nearby"
        case .getMenuList(let storeId, _):
            return "/stores/\(storeId)/menus"
        case .getMenuDetail(let menuId):
            return "/menus/\(menuId)"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case let .getStoreList(category, latitude, longitude):
            var parameters = [String: Any]()
            if let category = category {
                parameters["category"] = category
            }
            if let latitude = latitude {
                parameters["latitude"] = latitude
            }
            if let longitude = longitude {
                parameters["longitude"] = longitude
            }
            return parameters.isEmpty ? .requestPlain : .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )

        case .getStoreDetail:
            return .requestPlain

        case let .searchStore(keyword, page):
            return .requestParameters(
                parameters: ["keyword": keyword, "page": page],
                encoding: URLEncoding.queryString
            )

        case let .getPopularStores(limit):
            return .requestParameters(
                parameters: ["limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .getNearbyStores(latitude, longitude, radius):
            return .requestParameters(
                parameters: [
                    "latitude": latitude,
                    "longitude": longitude,
                    "radius": radius
                ],
                encoding: URLEncoding.queryString
            )

        case let .getMenuList(_, category):
            if let category = category {
                return .requestParameters(
                    parameters: ["category": category],
                    encoding: URLEncoding.queryString
                )
            }
            return .requestPlain

        case .getMenuDetail:
            return .requestPlain
        }
    }
}
