//
//  StoreAPI+User.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import Foundation
import Moya

extension StoreAPI.User: BaseAPI {
    var endpoint: String {
        switch self {
        case .fetchNearbyStores: return "/stores"
        case .fetchStoreDetail(let id): return "/stores/\(id)"
        case .toggleLike(let id, _): return "/stores/\(id)/like"
        case .searchStores: return "/stores/search"
        case .fetchPopularStores: return "/stores/popular-stores"
        case .fetchPopularKeywords: return "/stores/searches-popular"
        case .fetchMyLikedStores: return "/stores/likes/me"
        case .fetchUserReviews(let userId, _, _, _): return "/stores/reviews/users/\(userId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .toggleLike: return .post
        default: return .get
        }
    }

    var task: Task {
        switch self {
        case let .fetchNearbyStores(category, lon, lat, dist, next, limit, order_by):
            var params: [String: Any] = [
                "order_by": order_by
            ]
            if let category = category { params["category"] = category }
            if let lon { params["longitude"] = lon }
            if let lat { params["latitude"] = lat }
            if let dist { params["maxDistance"] = dist }
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }

            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .fetchStoreDetail:
            return .requestPlain

        case .toggleLike(_, let status):
            return .requestJSONEncodable(LikeStatusRequest(likeStatus: status))

        case .searchStores(let name):
            return .requestParameters(parameters: ["name": name], encoding: URLEncoding.queryString)

        case .fetchPopularStores(let category):
            var params: [String: Any] = [:]
            if let category = category { params["category"] = category }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .fetchPopularKeywords:
            return .requestPlain

        case .fetchMyLikedStores(let category, let next, let limit):
            var params: [String: Any] = [:]
            if let category = category { params["category"] = category }
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .fetchUserReviews(_, let category, let next, let limit):
            var params: [String: Any] = [:]
            if let category = category { params["category"] = category }
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }
}
