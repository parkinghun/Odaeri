//
//  StoreAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import Foundation
import Moya

enum StoreAPI {
    enum User {
        case fetchNearbyStores(category: String?, lon: Double?, lat: Double?, distance: Int?, next: String?, limit: Int?, order_by: String)
        case fetchStoreDetail(storeId: String)
        case toggleLike(storeId: String, status: Bool)
        case searchStores(name: String)
        case fetchPopularStores(category: String?)
        case fetchPopularKeywords
        case fetchMyLikedStores(category: String?, next: String?, limit: Int?)
        case fetchUserReviews(userId: String, category: String?, next: String?, limit: Int?)
    }

    enum Admin {
        case uploadImages(files: [MultipartFormData])
        case create(request: StoreRequest)
        case update(storeId: String, request: StoreRequest)
    }
}
