//
//  CommunityCommentAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum CommunityCommentAPI {
    case addComment(postId: String, parentId: String?, content: String)
    case updateComment(postId: String, commentId: String, content: String)
    case deleteComment(postId: String, commentId: String)
}

extension CommunityCommentAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case let .addComment(postId, _, _):
            return "/posts/\(postId)/comments"
        case let .updateComment(postId, commentId, _):
            return "/posts/\(postId)/comments/\(commentId)"
        case let .deleteComment(postId, commentId) :
            return "/posts/\(postId)/comments/\(commentId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .addComment:
            return .post
        case .updateComment:
            return .put
        case .deleteComment:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case let .addComment(_, parentId, content):
            // 대댓글 작성 시 parentCommentId 포함 (1뎁스까지만 허용)
            let request = CommunityCommentRequest(
                content: content,
                parentCommentId: (parentId?.isEmpty ?? true) ? nil : parentId
            )
            return .requestJSONEncodable(request)
            
        case let .updateComment(_, _, content):
            // 수정 시 작성자 본인만 가능, content 전달
            let parameters: [String: Any] = ["content": content]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .deleteComment:
            // 삭제 시 하위 대댓글도 함께 삭제됨
            return .requestPlain
        }
    }
    
    var headerSet: HeaderSet {
        return .authenticated
    }
}
