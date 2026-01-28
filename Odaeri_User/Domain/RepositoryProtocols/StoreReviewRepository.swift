//
//  StoreReviewRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

protocol StoreReviewRepository {
    func uploadReviewImages(
        storeId: String,
        imageDataList: [Data]
    ) -> AnyPublisher<[String], NetworkError>

    func createReview(
        storeId: String,
        content: String,
        rating: Int,
        imageUrls: [String],
        orderCode: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError>

    func createReview(
        storeId: String,
        request: StoreReviewRequest
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError>

    func fetchReviews(
        storeId: String,
        next: String?,
        limit: Int?,
        orderBy: String?
    ) -> AnyPublisher<StoreReviewListResult, NetworkError>

    func fetchReviewDetail(
        storeId: String,
        reviewId: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError>

    func updateReview(
        storeId: String,
        reviewId: String,
        content: String,
        rating: Int,
        imageUrls: [String]
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError>

    func updateReview(
        storeId: String,
        reviewId: String,
        request: StoreReviewRequest
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError>

    func deleteReview(
        storeId: String,
        reviewId: String
    ) -> AnyPublisher<Void, NetworkError>

    func fetchReviewRatings(
        storeId: String
    ) -> AnyPublisher<[ReviewRatingEntity], NetworkError>
}
