//
//  CommunityCommentDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum CommunityCommentDTOMapper {
    static func toEntity(_ response: CommunityCommentResponse, currentUserId: String) -> CommunityCommentEntity {
        CommunityCommentEntity(
            commentId: response.commentId,
            content: response.content,
            createdAt: response.createdAt,
            userNick: response.creator.nick,
            userProfileImage: response.creator.profileImage,
            isMine: response.creator.userId == currentUserId
        )
    }
}
