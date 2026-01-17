//
//  CommunityCommentDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

struct CommunityCommentRequest: Encodable {
    let content: String
    let parentCommentId: String? // camelCase로 정의

    enum CodingKeys: String, CodingKey {
        case content
        case parentCommentId = "parent_comment_id"
    }
}

struct CommunityCommentResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: Creator

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}

