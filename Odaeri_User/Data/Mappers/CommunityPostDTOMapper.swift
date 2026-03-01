//
//  CommunityPostDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum CommunityPostDTOMapper {
    static func toEntity(_ response: CommunityPostResponse, currentUserId: String) -> CommunityPostEntity {
        CommunityPostEntity(
            postId: response.postId,
            category: response.category,
            title: response.title,
            content: response.content,
            store: StoreDTOMapper.toEntity(response.store),
            geolocation: StoreDTOMapper.toEntity(response.geolocation),
            creator: StoreDTOMapper.toEntity(response.creator),
            files: response.files,
            isLike: response.isLike,
            likeCount: response.likeCount,
            comments: (response.comments ?? []).map { toEntity($0, currentUserId: currentUserId) },
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: CommunityPostCommentResponse, currentUserId: String) -> CommunityPostCommentEntity {
        CommunityPostCommentEntity(
            commentId: response.commentId,
            content: response.content,
            createdAt: response.createdAt.toDate(),
            creator: StoreDTOMapper.toEntity(response.creator),
            replies: (response.replies ?? []).map { toEntity($0, currentUserId: currentUserId) },
            isMine: response.creator.userId == currentUserId,
            isExpanded: false
        )
    }

    static func toEntity(_ response: CommunityPostReplyResponse, currentUserId: String) -> CommunityPostReplyEntity {
        CommunityPostReplyEntity(
            commentId: response.commentId,
            content: response.content,
            createdAt: response.createdAt.toDate(),
            creator: StoreDTOMapper.toEntity(response.creator),
            isMine: response.creator.userId == currentUserId
        )
    }
}
