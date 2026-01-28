//
//  StoreReviewRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya

final class StoreReviewRepositoryImpl: StoreReviewRepository {
    private let provider = MoyaProvider<StoreReviewAPI>()
    private let mediaUploadProvider = MoyaProvider<MediaUploadAPI>()

    func uploadReviewImages(
        storeId: String,
        imageDataList: [Data]
    ) -> AnyPublisher<[String], NetworkError> {
        let multiparts = imageDataList.map { data in
            MultipartFormData(
                provider: .data(data),
                name: "files",
                fileName: "image_\(UUID().uuidString).jpg",
                mimeType: "image/jpeg"
            )
        }

        return mediaUploadProvider.requestPublisher(
            .storeReviewUpload(storeId: storeId, files: multiparts)
        )
        .map { (response: StoreReviewImageUploadResponse) in
            response.reviewImageUrls
        }
        .eraseToAnyPublisher()
    }

    func createReview(
        storeId: String,
        content: String,
        rating: Int,
        imageUrls: [String],
        orderCode: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        let request = StoreReviewRequest(
            content: content,
            rating: rating,
            imageUrls: imageUrls,
            orderCode: orderCode
        )

        return createReview(storeId: storeId, request: request)
    }

    func createReview(
        storeId: String,
        request: StoreReviewRequest
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        provider.requestPublisher(.createReview(
            storeId: storeId,
            request: request
        ))
        .map { (response: StoreReviewResponse) in
            StoreReviewDetailEntity(from: response)
        }
        .eraseToAnyPublisher()
    }

    func fetchReviews(
        storeId: String,
        next: String?,
        limit: Int?,
        orderBy: String?
    ) -> AnyPublisher<StoreReviewListResult, NetworkError> {
        provider.requestPublisher(.fetchReviews(
            storeId: storeId,
            next: next,
            limit: limit,
            orderBy: orderBy
        ))
        .map { (response: StoreReviewListReponse) in
            let reviews = response.data.map { StoreReviewEntity(from: $0) }
            return StoreReviewListResult(
                reviews: reviews,
                nextCursor: response.nextCursot
            )
        }
        .eraseToAnyPublisher()
    }

    func fetchReviewDetail(
        storeId: String,
        reviewId: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        provider.requestPublisher(.fetchReviewDetail(
            storeId: storeId,
            reviewId: reviewId
        ))
        .map { (response: StoreReviewResponse) in
            StoreReviewDetailEntity(from: response)
        }
        .eraseToAnyPublisher()
    }

    func updateReview(
        storeId: String,
        reviewId: String,
        request: StoreReviewRequest
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        provider.requestPublisher(.updateReview(
            storeId: storeId,
            reviewId: reviewId,
            request: request
        ))
        .map { (response: StoreReviewResponse) in
            StoreReviewDetailEntity(from: response)
        }
        .eraseToAnyPublisher()
    }

    func updateReview(
        storeId: String,
        reviewId: String,
        content: String,
        rating: Int,
        imageUrls: [String]
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        let request = StoreReviewRequest(
            updateContent: content,
            rating: rating,
            imageUrls: imageUrls
        )

        return updateReview(storeId: storeId, reviewId: reviewId, request: request)
    }

    func deleteReview(
        storeId: String,
        reviewId: String
    ) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.deleteReview(
            storeId: storeId,
            reviewId: reviewId
        ))
    }

    func fetchReviewRatings(
        storeId: String
    ) -> AnyPublisher<[ReviewRatingEntity], NetworkError> {
        provider.requestPublisher(.fetchReviewRatings(storeId: storeId))
            .map { (response: ReviewRatingResponse) in
                response.data.map { ReviewRatingEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }
}
