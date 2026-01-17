//
//  PostBackgroundManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation
import Combine
import UIKit

enum PostUploadStatus {
    case uploading
    case failed
    case success
}

struct PendingPost: Identifiable {
    let id: String
    let category: String
    let title: String
    let content: String
    let storeId: String
    let storeName: String
    let uploadItems: [UploadItem]
    let latitude: Double?
    let longitude: Double?
    var status: PostUploadStatus
    let createdAt: Date

    init(
        category: String,
        title: String,
        content: String,
        storeId: String,
        storeName: String,
        mediaItems: [CommunityPostMediaItem],
        latitude: Double?,
        longitude: Double?
    ) {
        self.id = UUID().uuidString
        self.category = category
        self.title = title
        self.content = content
        self.storeId = storeId
        self.storeName = storeName
        self.uploadItems = mediaItems.compactMap { item in
            switch item.kind {
            case .image(let image):
                return .image(image)
            case .video(_, let url):
                return .video(url)
            case .remote:
                return nil
            }
        }
        self.latitude = latitude
        self.longitude = longitude
        self.status = .uploading
        self.createdAt = Date()
    }

    func toTemporaryEntity(creator: CreatorEntity, store: StoreEntity) -> CommunityPostEntity {
        CommunityPostEntity.temporary(
            postId: id,
            category: category,
            title: title,
            content: content,
            store: store,
            geolocation: GeolocationEntity(
                longitude: longitude ?? 0.0,
                latitude: latitude ?? 0.0
            ),
            creator: creator,
            files: [],
            createdAt: createdAt
        )
    }
}

final class PostBackgroundManager {
    static let shared = PostBackgroundManager()

    private let pendingPostsSubject = CurrentValueSubject<[PendingPost], Never>([])
    private let postRepository: CommunityPostRepository
    private let mediaUploadManager: MediaUploadManager
    private var cancellables = Set<AnyCancellable>()

    private init(
        postRepository: CommunityPostRepository = CommunityPostRepositoryImpl(),
        mediaUploadManager: MediaUploadManager = .shared
    ) {
        self.postRepository = postRepository
        self.mediaUploadManager = mediaUploadManager
    }

    var pendingPostsPublisher: AnyPublisher<[PendingPost], Never> {
        pendingPostsSubject.eraseToAnyPublisher()
    }

    func startUpload(
        category: String,
        title: String,
        content: String,
        storeId: String,
        storeName: String,
        mediaItems: [CommunityPostMediaItem],
        latitude: Double?,
        longitude: Double?
    ) {
        let pendingPost = PendingPost(
            category: category,
            title: title,
            content: content,
            storeId: storeId,
            storeName: storeName,
            mediaItems: mediaItems,
            latitude: latitude,
            longitude: longitude
        )

        var currentPosts = pendingPostsSubject.value
        currentPosts.insert(pendingPost, at: 0)
        pendingPostsSubject.send(currentPosts)

        executeUpload(post: pendingPost)
    }

    func retryUpload(id: String) {
        guard let post = pendingPostsSubject.value.first(where: { $0.id == id }) else { return }

        updatePostStatus(id: id, status: .uploading)
        executeUpload(post: post)
    }

    func startUpdate(
        postId: String,
        category: String,
        title: String,
        content: String,
        storeId: String,
        latitude: Double?,
        longitude: Double?,
        mediaItems: [CommunityPostMediaItem]
    ) {
        var remoteURLs: [String] = []
        var newUploadItems: [UploadItem] = []
        var indexMap: [(index: Int, isRemote: Bool)] = []

        for (index, item) in mediaItems.enumerated() {
            switch item.kind {
            case let .remote(url, thumbnailUrl, isVideo):
                if isVideo, let thumbUrl = thumbnailUrl {
                    remoteURLs.append(thumbUrl)
                    remoteURLs.append(url)
                } else {
                    remoteURLs.append(url)
                }
                indexMap.append((index, true))
            case .image(let image):
                newUploadItems.append(.image(image))
                indexMap.append((index, false))
            case .video(_, let url):
                newUploadItems.append(.video(url))
                indexMap.append((index, false))
            }
        }

        if newUploadItems.isEmpty {
            let finalURLs = remoteURLs.isEmpty ? nil : remoteURLs
            submitUpdate(
                postId: postId,
                category: category,
                title: title,
                content: content,
                storeId: storeId,
                latitude: latitude,
                longitude: longitude,
                fileUrls: finalURLs
            )
        } else {
            mediaUploadManager.uploadMedias(
                newUploadItems,
                config: .communityDefault,
                progress: { _ in }
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[PostBackgroundManager] Update media upload failed: \(error.errorDescription ?? "Unknown")")
                    }
                },
                receiveValue: { [weak self] newURLs in
                    let mergedURLs = self?.mergeMediaURLs(
                        indexMap: indexMap,
                        remoteURLs: remoteURLs,
                        newURLs: newURLs
                    ) ?? []

                    self?.submitUpdate(
                        postId: postId,
                        category: category,
                        title: title,
                        content: content,
                        storeId: storeId,
                        latitude: latitude,
                        longitude: longitude,
                        fileUrls: mergedURLs.isEmpty ? nil : mergedURLs
                    )
                }
            )
            .store(in: &cancellables)
        }
    }

    private func mergeMediaURLs(
        indexMap: [(index: Int, isRemote: Bool)],
        remoteURLs: [String],
        newURLs: [String]
    ) -> [String] {
        var result: [String] = []
        var remoteIndex = 0
        var newIndex = 0

        for item in indexMap {
            if item.isRemote {
                if remoteIndex < remoteURLs.count {
                    result.append(remoteURLs[remoteIndex])
                    remoteIndex += 1
                }
            } else {
                if newIndex < newURLs.count {
                    result.append(newURLs[newIndex])
                    newIndex += 1
                }
            }
        }

        return result
    }

    private func submitUpdate(
        postId: String,
        category: String,
        title: String,
        content: String,
        storeId: String,
        latitude: Double?,
        longitude: Double?,
        fileUrls: [String]?
    ) {
        let request = CommunityPostUpdateRequest(
            category: category,
            title: title,
            content: content,
            storeId: storeId,
            latitude: latitude,
            longitude: longitude,
            files: fileUrls
        )

        postRepository.updatePost(postId: postId, request: request)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[PostBackgroundManager] Update failed: \(error.errorDescription ?? "Unknown")")
                    }
                },
                receiveValue: { _ in
                    print("[PostBackgroundManager] Update success: \(postId)")
                    NotificationCenter.default.post(name: .communityPostDidUpdate, object: nil)
                }
            )
            .store(in: &cancellables)
    }

    private func executeUpload(post: PendingPost) {
        if post.uploadItems.isEmpty {
            submitPost(post: post, fileUrls: [])
        } else {
            uploadMediaFiles(post: post)
        }
    }

    private func uploadMediaFiles(post: PendingPost) {
        mediaUploadManager.uploadMedias(
            post.uploadItems,
            config: .communityDefault,
            progress: { _ in }
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[PostBackgroundManager] Media upload failed: \(error.errorDescription ?? "Unknown")")
                    self?.updatePostStatus(id: post.id, status: .failed)
                }
            },
            receiveValue: { [weak self] fileUrls in
                self?.submitPost(post: post, fileUrls: fileUrls)
            }
        )
        .store(in: &cancellables)
    }

    private func submitPost(post: PendingPost, fileUrls: [String]) {
        let request = CommunityPostCreateRequest(
            category: post.category,
            title: post.title,
            content: post.content,
            storeId: post.storeId,
            latitude: post.latitude ?? 0.0,
            longitude: post.longitude ?? 0.0,
            files: fileUrls
        )

        postRepository.createPost(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[PostBackgroundManager] Post creation failed: \(error.errorDescription)")
                        self?.updatePostStatus(id: post.id, status: .failed)
                    }
                },
                receiveValue: { [weak self] _ in
                    print("[PostBackgroundManager] Post created successfully")
                    self?.removePost(id: post.id)
                    NotificationCenter.default.post(name: .communityPostDidUpdate, object: nil)
                }
            )
            .store(in: &cancellables)
    }

    private func updatePostStatus(id: String, status: PostUploadStatus) {
        var currentPosts = pendingPostsSubject.value
        guard let index = currentPosts.firstIndex(where: { $0.id == id }) else { return }

        currentPosts[index].status = status
        pendingPostsSubject.send(currentPosts)
    }

    private func removePost(id: String) {
        var currentPosts = pendingPostsSubject.value
        currentPosts.removeAll { $0.id == id }
        pendingPostsSubject.send(currentPosts)
    }
}
