//
//  CommunityCommentEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

struct CommunityCommentEntity {
    let commentId: String
    let content: String
    let createdAt: String
    let userNick: String
    let userProfileImage: String?
    let isMine: Bool // 본인 작성 여부 판단
}
