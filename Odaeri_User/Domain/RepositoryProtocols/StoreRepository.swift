//
//  StoreRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Combine

protocol StoreRepository {
    func fetchNearbyStores(category: String?, longitude: Double, latitude: Double, distance: Int, next: String?, limit: Int?) -> AnyPublisher<(stores: [StoreEntity], nextCursor: String?), NetworkError>

    func fetchStoreDetail(storeId: String) -> AnyPublisher<StoreEntity, NetworkError>

    func toggleLike(storeId: String, status: Bool) -> AnyPublisher<Void, NetworkError>

    func searchStores(name: String) -> AnyPublisher<[StoreEntity], NetworkError>

    func fetchPopularStores(category: String?) -> AnyPublisher<[StoreEntity], NetworkError>

    func fetchPopularKeywords() -> AnyPublisher<[String], NetworkError>

    func fetchMyLikedStores(category: String?, next: String?, limit: Int?) -> AnyPublisher<(stores: [StoreEntity], nextCursor: String?), NetworkError>

    func fetchUserReviews(userId: String, category: String?, next: String?, limit: Int?) -> AnyPublisher<(reviews: [ReviewItem], nextCursor: String?), NetworkError>
}
