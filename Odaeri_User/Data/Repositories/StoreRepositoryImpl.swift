//
//  StoreRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Combine
import Moya

final class StoreRepositoryImpl: StoreRepository {
    private let provider = MoyaProvider<StoreAPI.User>()

    func fetchNearbyStores(
        category: String?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Int?,
        next: String?,
        limit: Int?,
        orderBy: String
    ) -> AnyPublisher<(stores: [StoreEntity], nextCursor: String?), NetworkError> {
        provider.requestPublisher(.fetchNearbyStores(
            category: category,
            lon: longitude,
            lat: latitude,
            maxDistance: maxDistance,
            next: next,
            limit: limit,
            order_by: orderBy
        ))
        .map { (response: StoreListResponse) in
            let stores = response.data.map { StoreEntity(from: $0) }
            return (stores: stores, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }

    func fetchStoreDetail(storeId: String) -> AnyPublisher<StoreEntity, NetworkError> {
        provider.requestPublisher(.fetchStoreDetail(storeId: storeId))
            .map { (response: StoreResponse) in
                StoreEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func toggleLike(storeId: String, status: Bool) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.toggleLike(storeId: storeId, status: status))
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }

    func searchStores(name: String) -> AnyPublisher<[StoreEntity], NetworkError> {
        provider.requestPublisher(.searchStores(name: name))
            .map { (response: StoreListResponse) in
                response.data.map { StoreEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func fetchPopularStores(category: String?) -> AnyPublisher<[StoreEntity], NetworkError> {
        provider.requestPublisher(.fetchPopularStores(category: category))
            .map { (response: StoreListResponse) in
                response.data.map { StoreEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func fetchPopularKeywords() -> AnyPublisher<[String], NetworkError> {
        provider.requestPublisher(.fetchPopularKeywords)
            .map { (response: PopularKeywordsResponse) in
                response.data
            }
            .eraseToAnyPublisher()
    }

    func fetchMyLikedStores(
        category: String?,
        next: String?,
        limit: Int?
    ) -> AnyPublisher<(stores: [StoreEntity], nextCursor: String?), NetworkError> {
        provider.requestPublisher(.fetchMyLikedStores(category: category, next: next, limit: limit))
            .map { (response: StoreListResponse) in
                let stores = response.data.map { StoreEntity(from: $0) }
                return (stores: stores, nextCursor: response.nextCursor)
            }
            .eraseToAnyPublisher()
    }

    func fetchUserReviews(
        userId: String,
        category: String?,
        next: String?,
        limit: Int?
    ) -> AnyPublisher<(reviews: [ReviewItem], nextCursor: String?), NetworkError> {
        provider.requestPublisher(.fetchUserReviews(userId: userId, category: category, next: next, limit: limit))
            .map { (response: ReviewResponse) in
                (reviews: response.data, nextCursor: response.nextCursor)
            }
            .eraseToAnyPublisher()
    }
}
