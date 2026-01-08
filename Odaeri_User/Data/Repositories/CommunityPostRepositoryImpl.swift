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
                CommunityPostEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func updatePost(postId: String, request: CommunityPostUpdateRequest) -> AnyPublisher<CommunityPostEntity, NetworkError> {
        provider.requestPublisher(.updatePost(postId: postId, request: request))
            .map { (response: CommunityPostResponse) in
                CommunityPostEntity(from: response)
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
                CommunityPostEntity(from: response)
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
            let posts = response.data.map { CommunityPostEntity(from: $0) }
            return (posts: posts, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }

    func searchPosts(title: String) -> AnyPublisher<[CommunityPostEntity], NetworkError> {
        provider.requestPublisher(.searchPosts(title: title))
            .map { (response: CommunityPostListResponse) in
                response.data.map { CommunityPostEntity(from: $0) }
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
            let posts = response.data.map { CommunityPostEntity(from: $0) }
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
            let posts = response.data.map { CommunityPostEntity(from: $0) }
            return (posts: posts, nextCursor: response.nextCursor)
        }
        .eraseToAnyPublisher()
    }
}
