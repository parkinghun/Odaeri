//
//  CommunityCommentRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya

final class CommunityCommentRepositoryImpl: CommunityCommentRepository {
    private let provider = ProviderFactory.makeCommunityCommentProvider()

    func addComment(postId: String, parentId: String?, content: String) -> AnyPublisher<CommunityCommentEntity, NetworkError> {
        provider.requestPublisher(.addComment(postId: postId, parentId: parentId, content: content))
            .map { (response: CommunityCommentResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return CommunityCommentDTOMapper.toEntity(response, currentUserId: currentUserId)
            }
            .eraseToAnyPublisher()
    }

    func updateComment(postId: String, commentId: String, content: String) -> AnyPublisher<CommunityCommentEntity, NetworkError> {
        provider.requestPublisher(.updateComment(postId: postId, commentId: commentId, content: content))
            .map { (response: CommunityCommentResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return CommunityCommentDTOMapper.toEntity(response, currentUserId: currentUserId)
            }
            .eraseToAnyPublisher()
    }

    func deleteComment(postId: String, commentId: String) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.deleteComment(postId: postId, commentId: commentId))
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }
}
