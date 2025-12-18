//
//  CommunityCommentAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum CommunityCommentAPI {
    case getComments(postId: Int, page: Int, limit: Int)
    case createComment(postId: Int, content: String, parentCommentId: Int?)
    case updateComment(commentId: Int, content: String)
    case deleteComment(commentId: Int)
    case likeComment(commentId: Int)
    case unlikeComment(commentId: Int)
}

extension CommunityCommentAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .getComments(let postId, _, _):
            return "/community/posts/\(postId)/comments"
        case .createComment(let postId, _, _):
            return "/community/posts/\(postId)/comments"
        case .updateComment(let commentId, _):
            return "/community/comments/\(commentId)"
        case .deleteComment(let commentId):
            return "/community/comments/\(commentId)"
        case .likeComment(let commentId):
            return "/community/comments/\(commentId)/like"
        case .unlikeComment(let commentId):
            return "/community/comments/\(commentId)/unlike"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createComment, .likeComment:
            return .post
        case .getComments:
            return .get
        case .updateComment:
            return .patch
        case .deleteComment, .unlikeComment:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .getComments(_, page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .createComment(_, content, parentCommentId):
            var parameters: [String: Any] = ["content": content]
            if let parentCommentId = parentCommentId {
                parameters["parentCommentId"] = parentCommentId
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case let .updateComment(_, content):
            return .requestParameters(
                parameters: ["content": content],
                encoding: JSONEncoding.default
            )

        case .deleteComment, .likeComment, .unlikeComment:
            return .requestPlain
        }
    }
}
