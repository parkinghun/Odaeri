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
}

struct GeolocationEntity {
    let longitude: Double
    let latitude: Double

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
