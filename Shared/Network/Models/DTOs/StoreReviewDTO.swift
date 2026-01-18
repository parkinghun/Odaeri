//
//  StoreReviewDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

// API - 2번 응답
struct StoreReviewListReponse: Decodable {
    let data: [StoreRevewItemDTO]
    let nextCursot: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursot = "next_cursor"
    }
}

struct StoreRevewItemDTO: Decodable {
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
    
    enum CodingKeys: String, CodingKey {
        case reviewId = "review_id"
        case content
        case rating
        case reviewImageUrls = "review_image_urls"
        case orderMenuList = "order_menu_list"
        case creator
        case userTotalReviewCount = "user_total_review_count"
        case userTotalRating = "user_total_rating"
        case createdAt
        case updatedAt
    }
}

// API - 1, 3, 4번 응답 공용
struct StoreReviewResponse: Decodable {
    let reviewID: String
    let content: String
    let rating: Int
    let store: StoreSummary
    let reviewImageUrls: [String]
    let orderMenuList: [String]
    let creator: Creator
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case reviewID = "review_id"
        case content, rating, store
        case reviewImageUrls = "review_image_urls"
        case orderMenuList = "order_menu_list"
        case creator, createdAt, updatedAt
    }
}

// API - 6번 응답
struct ReviewRatingResponse: Decodable {
    let data: [RatingData]
}

struct RatingData: Decodable {
    let rating: Int
    let count: Int
}

// 리뷰 작성 / 수정 요청
struct StoreReviewRequest: Codable {
    let content: String
    let rating: Int
    let imageUrls: [String]
    let orderCode: String?  // 작성 시 필수, 수정 시 nil/
    
    enum CodingKeys: String, CodingKey {
        case content
        case rating
        case imageUrls = "review_image_urls"
        case orderCode = "order_code"
    }
}
