//
//  UserAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum UserAPI {
    case getProfile
    case updateProfile(nickname: String?, profileImageURL: String?)
    case uploadProfileImage(imageData: Data)
    case getMyOrders(page: Int, limit: Int)
    case getFavoriteStores
    case addFavoriteStore(storeId: Int)
    case removeFavoriteStore(storeId: Int)
}

extension UserAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .getProfile, .updateProfile:
            return "/users/me"
        case .uploadProfileImage:
            return "/users/me/profile-image"
        case .getMyOrders:
            return "/users/me/orders"
        case .getFavoriteStores:
            return "/users/me/favorite-stores"
        case .addFavoriteStore(let storeId):
            return "/users/me/favorite-stores/\(storeId)"
        case .removeFavoriteStore(let storeId):
            return "/users/me/favorite-stores/\(storeId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getProfile, .getMyOrders, .getFavoriteStores:
            return .get
        case .updateProfile:
            return .patch
        case .uploadProfileImage, .addFavoriteStore:
            return .post
        case .removeFavoriteStore:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case .getProfile, .getFavoriteStores:
            return .requestPlain

        case let .updateProfile(nickname, profileImageURL):
            var parameters = [String: Any]()
            if let nickname = nickname {
                parameters["nickname"] = nickname
            }
            if let profileImageURL = profileImageURL {
                parameters["profileImageURL"] = profileImageURL
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case let .uploadProfileImage(imageData):
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "profile.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])

        case let .getMyOrders(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case .addFavoriteStore, .removeFavoriteStore:
            return .requestPlain
        }
    }
}
