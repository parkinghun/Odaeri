//
//  CommunityPostRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import Foundation
import Combine

protocol CommunityPostRepository {
    func uploadPostFiles(files: [CommunityPostAPI.UploadFileRequest]) -> AnyPublisher<[String], NetworkError>
    func createPost(request: CommunityPostCreateRequest) -> AnyPublisher<CommunityPostEntity, NetworkError>
    func updatePost(postId: String, request: CommunityPostUpdateRequest) -> AnyPublisher<CommunityPostEntity, NetworkError>
    func deletePost(postId: String) -> AnyPublisher<Void, NetworkError>
    func toggleLike(postId: String, status: Bool) -> AnyPublisher<Bool, NetworkError>
    func fetchPostDetail(postId: String) -> AnyPublisher<CommunityPostEntity, NetworkError>
    func fetchPostsByGeolocation(
        category: String?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Int?,
        limit: Int?,
        next: String?,
        orderBy: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError>
    func searchPosts(title: String) -> AnyPublisher<[CommunityPostEntity], NetworkError>
    func fetchPostsByUser(
        userId: String,
        category: String?,
        limit: Int?,
        next: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError>
    func fetchMyLikedPosts(
        category: String?,
        limit: Int?,
        next: String?
    ) -> AnyPublisher<(posts: [CommunityPostEntity], nextCursor: String?), NetworkError>
}
