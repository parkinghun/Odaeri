//
//  CommunityPostRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import Foundation
import Combine
import Moya

final class CommunityPostRepositoryImpl: CommunityPostRepository {
    private let provider = ProviderFactory.makeCommunityPostProvider()

    func uploadPostFiles(files: [CommunityPostAPI.UploadFileRequest]) -> AnyPublisher<[String], NetworkError> {
        provider.requestPublisher(.uploadFiles(files: files))
            .map { (response: CommunityPostFileUploadResponse) in
                response.files
            }
            .eraseToAnyPublisher()
    }

    func createPost(request: CommunityPostCreateRequest) -> AnyPublisher<CommunityPostEntity, NetworkError> {
        provider.requestPublisher(.createPost(request: request))
            .map { (response: CommunityPostResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return CommunityPostDTOMapper.toEntity(response, currentUserId: currentUserId)
            }
            .eraseToAnyPublisher()
    }

    func updatePost(postId: String, request: CommunityPostUpdateRequest) -> AnyPublisher<CommunityPostEntity, NetworkError> {
        provider.requestPublisher(.updatePost(postId: postId, request: request))
            .map { (response: CommunityPostResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return CommunityPostDTOMapper.toEntity(response, currentUserId: currentUserId)
            }
            .eraseToAnyPublisher()
    }

    func deletePost(postId: String) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.deletePost(postId: postId))
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }

    func toggleLike(postId: String, status: Bool) -> AnyPublisher<Bool, NetworkError> {
        let request = LikeStatusRequest(likeStatus: status)
        return provider.requestPublisher(.likePost(postId: postId, request: request))
            .map { (response: CommunityPostLikeResponse) in
                response.likeStatus
            }
            .eraseToAnyPublisher()
    }

    func fetchPostDetail(postId: String) -> AnyPublisher<CommunityPostEntity, NetworkError> {
        provider.requestPublisher(.fetchPostDetail(postId: postId))
            .map { (response: CommunityPostResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return CommunityPostDTOMapper.toEntity(response, currentUserId: currentUserId)
            }
            .eraseToAnyPublisher()
    }

    func fetchPostsByGeolocation(
        category: String?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Int?,
        limit: Int?,
        next: String?,
        orderBy: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError> {
        provider.requestPublisher(
            .fetchPostsByGeolocation(
                category: category,
                longitude: longitude,
                latitude: latitude,
                maxDistance: maxDistance,
                limit: limit,
                next: next,
                orderBy: orderBy
            )
        )
        .map { (response: CommunityPostListResponse) in
            let currentUserId = UserManager.shared.currentUser?.userId ?? ""
            let posts = response.data.map { CommunityPostDTOMapper.toEntity($0, currentUserId: currentUserId) }
            return (posts: posts, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }

    func searchPosts(title: String) -> AnyPublisher<[CommunityPostEntity], NetworkError> {
        provider.requestPublisher(.searchPosts(title: title))
            .map { (response: CommunityPostListResponse) in
                let currentUserId = UserManager.shared.currentUser?.userId ?? ""
                return response.data.map { CommunityPostDTOMapper.toEntity($0, currentUserId: currentUserId) }
            }
            .eraseToAnyPublisher()
    }

    func fetchPostsByUser(
        userId: String,
        category: String?,
        limit: Int?,
        next: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError> {
        provider.requestPublisher(
            .fetchPostsByUser(userId: userId, category: category, limit: limit, next: next)
        )
        .map { (response: CommunityPostListResponse) in
            let currentUserId = UserManager.shared.currentUser?.userId ?? ""
            let posts = response.data.map { CommunityPostDTOMapper.toEntity($0, currentUserId: currentUserId) }
            return (posts: posts, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }

    func fetchMyLikedPosts(
        category: String?,
        limit: Int?,
        next: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError> {
        provider.requestPublisher(
            .fetchMyLikedPosts(category: category, limit: limit, next: next)
        )
        .map { (response: CommunityPostListResponse) in
            let currentUserId = UserManager.shared.currentUser?.userId ?? ""
            let posts = response.data.map { CommunityPostDTOMapper.toEntity($0, currentUserId: currentUserId) }
            return (posts: posts, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }
}
