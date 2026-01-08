//
//  CommunityPostEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import Foundation

struct CommunityPostEntity {
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: StoreEntity
    let geolocation: GeolocationEntity
    let creator: CreatorEntity
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [CommunityPostCommentEntity]
    let createdAt: Date?
    let updatedAt: Date?

    init(from response: CommunityPostResponse) {
        self.postId = response.postId
        self.category = response.category
        self.title = response.title
        self.content = response.content
        self.store = StoreEntity(from: response.store)
        self.geolocation = GeolocationEntity(from: response.geolocation)
        self.creator = CreatorEntity(from: response.creator)
        self.files = response.files
        self.isLike = response.isLike
        self.likeCount = response.likeCount
        self.comments = (response.comments ?? []).map { CommunityPostCommentEntity(from: $0) }
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}

struct GeolocationEntity {
    let longitude: Double
    let latitude: Double

    init(from response: Geolocation) {
        self.longitude = response.longitude
        self.latitude = response.latitude
    }
}

struct CommunityPostCommentEntity {
    let commentId: String
    let content: String
    let createdAt: Date?
    let creator: CreatorEntity
    let replies: [CommunityPostReplyEntity]

    init(from response: CommunityPostCommentResponse) {
        self.commentId = response.commentId
        self.content = response.content
        self.createdAt = response.createdAt.toDate()
        self.creator = CreatorEntity(from: response.creator)
        self.replies = (response.replies ?? []).map { CommunityPostReplyEntity(from: $0) }
    }
}

struct CommunityPostReplyEntity {
    let commentId: String
    let content: String
    let createdAt: Date?
    let creator: CreatorEntity

    init(from response: CommunityPostReplyResponse) {
        self.commentId = response.commentId
        self.content = response.content
        self.createdAt = response.createdAt.toDate()
        self.creator = CreatorEntity(from: response.creator)
    }
}
