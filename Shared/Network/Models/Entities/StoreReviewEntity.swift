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
    let creator: CreatorEntity
    let userTotalReviewCount: Int
    let userTotalRating: Double
    let createdAt: Date?
    let updatedAt: Date?
    
    var isMe: Bool {
        creator.userId == UserDefaults.standard.string(forKey: "userId")
    }
}

struct StoreReviewDetailEntity {
    let reviewId: String
    let content: String
    let rating: Int
    let store: StoreEntity
    let reviewImageUrls: [String]
    let orderMenuList: [String]
    let creator: CreatorEntity
    let createdAt: Date?
    let updatedAt: Date?
}

struct ReviewRatingEntity {
    let rating: Int
    let count: Int
}

struct StoreReviewListResult {
    let reviews: [StoreReviewEntity]
    let nextCursor: String?
}
