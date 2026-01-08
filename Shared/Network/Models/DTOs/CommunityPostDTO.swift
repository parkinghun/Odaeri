//
//  CommunityPostDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import Foundation

struct CommunityPostFileUploadResponse: Decodable {
    let files: [String]
}

struct CommunityPostCreateRequest: Encodable {
    let category: String
    let title: String
    let content: String
    let storeId: String
    let latitude: Double
    let longitude: Double
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case category, title, content, latitude, longitude, files
        case storeId = "store_id"
    }
}

struct CommunityPostUpdateRequest: Encodable {
    let category: String?
    let title: String?
    let content: String?
    let storeId: String?
    let latitude: Double?
    let longitude: Double?
    let files: [String]?

    enum CodingKeys: String, CodingKey {
        case category, title, content, latitude, longitude, files
        case storeId = "store_id"
    }
}

struct CommunityPostListResponse: Decodable {
    let data: [CommunityPostResponse]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct CommunityPostResponse: Decodable {
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: StoreSummary
    let geolocation: Geolocation
    let creator: Creator
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [CommunityPostCommentResponse]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, title, content, store, geolocation, creator, files, comments, createdAt, updatedAt
        case isLike = "is_like"
        case likeCount = "like_count"
    }
}

struct CommunityPostCommentResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: Creator
    let replies: [CommunityPostReplyResponse]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content, createdAt, creator, replies
    }
}

struct CommunityPostReplyResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: Creator

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content, createdAt, creator
    }
}

struct CommunityPostLikeResponse: Decodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
