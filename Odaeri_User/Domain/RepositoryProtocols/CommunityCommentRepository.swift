//
//  CommunityCommentRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

protocol CommunityCommentRepository {
    func addComment(postId: String, parentId: String?, content: String) -> AnyPublisher<CommunityCommentEntity, NetworkError>
    func updateComment(postId: String, commentId: String, content: String) -> AnyPublisher<CommunityCommentEntity, NetworkError>
    func deleteComment(postId: String, commentId: String) -> AnyPublisher<Void, NetworkError>
}
