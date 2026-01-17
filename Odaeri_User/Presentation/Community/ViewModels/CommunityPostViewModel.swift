//
//  CommunityPostViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/16/26.
//

import Foundation
import Combine
import UIKit

final class CommunityPostViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: CommunityCoordinator?
    private let locationManager: LocationManager
    private let backgroundManager: PostBackgroundManager
    private let postRepository: CommunityPostRepository
    let postToEdit: CommunityPostEntity?

    init(
        postToEdit: CommunityPostEntity? = nil,
        locationManager: LocationManager = .shared,
        backgroundManager: PostBackgroundManager = .shared,
        postRepository: CommunityPostRepository = CommunityPostRepositoryImpl()
    ) {
        self.postToEdit = postToEdit
        self.locationManager = locationManager
        self.backgroundManager = backgroundManager
        self.postRepository = postRepository
    }

    struct Input {
        let category: AnyPublisher<String?, Never>
        let title: AnyPublisher<String?, Never>
        let content: AnyPublisher<String?, Never>
        let storeId: AnyPublisher<String?, Never>
        let storeName: AnyPublisher<String?, Never>
        let mediaItems: AnyPublisher<[CommunityPostMediaItem], Never>
        let storeButtonTapped: AnyPublisher<Void, Never>
        let doneButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let isDoneButtonEnabled: AnyPublisher<Bool, Never>
        let initialMediaItems: AnyPublisher<[CommunityPostMediaItem], Never>
    }

    func transform(input: Input) -> Output {
        let initialMediaItemsSubject = PassthroughSubject<[CommunityPostMediaItem], Never>()

        if let postToEdit = postToEdit {
            print("[CommunityPostViewModel] Loading existing media from files: \(postToEdit.files)")
            let items = loadExistingMediaItems(from: postToEdit.files)
            print("[CommunityPostViewModel] Loaded \(items.count) media items")
            DispatchQueue.main.async {
                initialMediaItemsSubject.send(items)
            }
        }

        input.storeButtonTapped
            .sink { [weak self] _ in
                self?.coordinator?.showStoreSearch()
            }
            .store(in: &cancellables)

        let isDoneButtonEnabled = Publishers.CombineLatest4(
            input.category,
            input.title,
            input.content,
            input.storeId
        )
        .map { [weak self] category, title, content, storeId in
            guard let category = category, !category.isEmpty else { return false }
            guard let title = title, !title.isEmpty else { return false }
            guard let content = content, !content.isEmpty else { return false }
            guard let storeId = storeId, !storeId.isEmpty else { return false }

            if let postToEdit = self?.postToEdit {
                let categoryChanged = category != postToEdit.category
                let titleChanged = title != postToEdit.title
                let contentChanged = content != postToEdit.content
                let storeChanged = storeId != postToEdit.store.storeId

                return categoryChanged || titleChanged || contentChanged || storeChanged
            }

            return true
        }
        .eraseToAnyPublisher()

        input.doneButtonTapped
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: false)
            .withLatestFrom(Publishers.CombineLatest4(
                input.category,
                input.title,
                input.content,
                Publishers.CombineLatest(input.storeId, input.storeName)
            ))
            .withLatestFrom(input.mediaItems)
            .sink { [weak self] combinedData in
                guard let self = self else { return }
                let (_, formData) = combinedData.0
                let mediaItems = combinedData.1
                let (category, title, content, storeData) = formData
                let (storeId, storeName) = storeData

                guard let category = category, !category.isEmpty,
                      let title = title, !title.isEmpty,
                      let content = content, !content.isEmpty,
                      let storeId = storeId, !storeId.isEmpty,
                      let storeName = storeName, !storeName.isEmpty else {
                    return
                }

                let location = self.locationManager.locationSubject.value
                let latitude = location?.coordinate.latitude
                let longitude = location?.coordinate.longitude

                if let postToEdit = self.postToEdit {
                    self.backgroundManager.startUpdate(
                        postId: postToEdit.postId,
                        category: category,
                        title: title,
                        content: content,
                        storeId: storeId,
                        latitude: latitude,
                        longitude: longitude,
                        mediaItems: mediaItems
                    )
                } else {
                    self.backgroundManager.startUpload(
                        category: category,
                        title: title,
                        content: content,
                        storeId: storeId,
                        storeName: storeName,
                        mediaItems: mediaItems,
                        latitude: latitude,
                        longitude: longitude
                    )
                }

                self.coordinator?.didFinishCreatePost()
            }
            .store(in: &cancellables)

        return Output(
            isDoneButtonEnabled: isDoneButtonEnabled,
            initialMediaItems: initialMediaItemsSubject.eraseToAnyPublisher()
        )
    }

    private func loadExistingMediaItems(from files: [String]) -> [CommunityPostMediaItem] {
        var items: [CommunityPostMediaItem] = []
        var i = 0

        while i < files.count {
            let currentURL = files[i]
            let isVideo = currentURL.lowercased().contains(".mp4") ||
                         currentURL.lowercased().contains(".mov") ||
                         currentURL.lowercased().contains(".m4v")

            if isVideo {
                let thumbnailURL = currentURL
                let videoURL = (i + 1 < files.count) ? files[i + 1] : currentURL

                items.append(CommunityPostMediaItem(
                    kind: .remote(url: videoURL, thumbnailUrl: thumbnailURL, isVideo: true)
                ))
                i += 2
            } else {
                items.append(CommunityPostMediaItem(
                    kind: .remote(url: currentURL, thumbnailUrl: nil, isVideo: false)
                ))
                i += 1
            }
        }

        return items
    }
}

extension Publisher {
    func withLatestFrom<Other: Publisher>(_ other: Other) -> AnyPublisher<(Self.Output, Other.Output), Self.Failure> where Other.Failure == Self.Failure {
        let upstream = self
        return upstream
            .map { upstreamValue in
                other.map { otherValue in (upstreamValue, otherValue) }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
