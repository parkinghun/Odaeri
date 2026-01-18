//
//  StoreReviewEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

struct StoreReviewEntity {
    let reviewId: String
    let content: String
    let rating: Int
    let reviewImageUrls: [String]
    let orderMenuList: [String]
    let creator: Creator
    let userTotalReviewCount: Int
    let userTotalRating: Double
    let createdAt: String
    let updatedAt: String
}

extension StoreReviewEntity {
    init(from dto: StoreRevewItemDTO) {
        self.reviewId = dto.reviewId
        self.content = dto.content
        self.rating = dto.rating
        self.reviewImageUrls = dto.reviewImageUrls
        self.orderMenuList = dto.orderMenuList
        self.creator = dto.creator
        self.userTotalReviewCount = dto.userTotalReviewCount
        self.userTotalRating = dto.userTotalRating
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}

struct StoreReviewDetailEntity {
    let reviewId: String
    let content: String
    let rating: Int
    let store: StoreSummary
    let reviewImageUrls: [String]
    let orderMenuList: [String]
    let creator: Creator
    let createdAt: String
    let updatedAt: String
}

extension StoreReviewDetailEntity {
    init(from dto: StoreReviewResponse) {
        self.reviewId = dto.reviewID
        self.content = dto.content
        self.rating = dto.rating
        self.store = dto.store
        self.reviewImageUrls = dto.reviewImageUrls
        self.orderMenuList = dto.orderMenuList
        self.creator = dto.creator
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}

struct ReviewRatingEntity {
    let rating: Int
    let count: Int
}

extension ReviewRatingEntity {
    init(from dto: RatingData) {
        self.rating = dto.rating
        self.count = dto.count
    }
}

struct StoreReviewListResult {
    let reviews: [StoreReviewEntity]
    let nextCursor: String?
}
