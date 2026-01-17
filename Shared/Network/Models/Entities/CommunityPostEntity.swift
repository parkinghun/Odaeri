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

    init(from response: CommunityPostResponse, currentUserId: String) {
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
        self.comments = (response.comments ?? []).map { CommunityPostCommentEntity(from: $0, currentUserId: currentUserId) }
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

    init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}

struct CommunityPostCommentEntity {
    let commentId: String
    let content: String
    let createdAt: Date?
    let creator: CreatorEntity
    let replies: [CommunityPostReplyEntity]
    let isMine: Bool
    var isExpanded: Bool

    init(from response: CommunityPostCommentResponse, currentUserId: String) {
        self.commentId = response.commentId
        self.content = response.content
        self.createdAt = response.createdAt.toDate()
        self.creator = CreatorEntity(from: response.creator)
        self.replies = (response.replies ?? []).map { CommunityPostReplyEntity(from: $0, currentUserId: currentUserId) }
        self.isMine = response.creator.userId == currentUserId
        self.isExpanded = false
    }

    init(
        commentId: String,
        content: String,
        createdAt: Date?,
        creator: CreatorEntity,
        replies: [CommunityPostReplyEntity],
        isMine: Bool,
        isExpanded: Bool
    ) {
        self.commentId = commentId
        self.content = content
        self.createdAt = createdAt
        self.creator = creator
        self.replies = replies
        self.isMine = isMine
        self.isExpanded = isExpanded
    }
}

struct CommunityPostReplyEntity {
    let commentId: String
    let content: String
    let createdAt: Date?
    let creator: CreatorEntity
    let isMine: Bool

    init(from response: CommunityPostReplyResponse, currentUserId: String) {
        self.commentId = response.commentId
        self.content = response.content
        self.createdAt = response.createdAt.toDate()
        self.creator = CreatorEntity(from: response.creator)
        self.isMine = response.creator.userId == currentUserId
    }

    init(
        commentId: String,
        content: String,
        createdAt: Date?,
        creator: CreatorEntity,
        isMine: Bool
    ) {
        self.commentId = commentId
        self.content = content
        self.createdAt = createdAt
        self.creator = creator
        self.isMine = isMine
    }
}

extension CommunityPostEntity {
    init(
        postId: String,
        category: String,
        title: String,
        content: String,
        store: StoreEntity,
        geolocation: GeolocationEntity,
        creator: CreatorEntity,
        files: [String],
        isLike: Bool,
        likeCount: Int,
        comments: [CommunityPostCommentEntity],
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.postId = postId
        self.category = category
        self.title = title
        self.content = content
        self.store = store
        self.geolocation = geolocation
        self.creator = creator
        self.files = files
        self.isLike = isLike
        self.likeCount = likeCount
        self.comments = comments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func temporary(
        postId: String,
        category: String,
        title: String,
        content: String,
        store: StoreEntity,
        geolocation: GeolocationEntity,
        creator: CreatorEntity,
        files: [String],
        createdAt: Date
    ) -> CommunityPostEntity {
        CommunityPostEntity(
            postId: postId,
            category: category,
            title: title,
            content: content,
            store: store,
            geolocation: geolocation,
            creator: creator,
            files: files,
            isLike: false,
            likeCount: 0,
            comments: [],
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
