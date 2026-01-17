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
    private let postRepository: CommunityPostRepository
    private let locationManager: LocationManager
    var onPostCreated: (() -> Void)?

    init(
        postRepository: CommunityPostRepository = CommunityPostRepositoryImpl(),
        locationManager: LocationManager = .shared
    ) {
        self.postRepository = postRepository
        self.locationManager = locationManager
    }

    struct PostData {
        let category: String
        let title: String
        let content: String
        let storeId: String
        let mediaItems: [CommunityPostMediaItem]
    }

    struct Input {
        let storeButtonTapped: AnyPublisher<Void, Never>
        let doneButtonTapped: AnyPublisher<Void, Never>
        let postData: AnyPublisher<PostData?, Never>
    }

    struct Output {
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let postCreated: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
        let errorSubject = PassthroughSubject<String, Never>()
        let postCreatedSubject = PassthroughSubject<Void, Never>()

        input.storeButtonTapped
            .sink { [weak self] _ in
                self?.coordinator?.showStoreSearch()
            }
            .store(in: &cancellables)

        input.doneButtonTapped
            .withLatestFrom(input.postData)
            .compactMap { $0 }
            .sink { [weak self] postData in
                self?.createPost(
                    postData: postData,
                    isLoadingSubject: isLoadingSubject,
                    errorSubject: errorSubject,
                    postCreatedSubject: postCreatedSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            postCreated: postCreatedSubject.eraseToAnyPublisher()
        )
    }

    private func createPost(
        postData: PostData,
        isLoadingSubject: CurrentValueSubject<Bool, Never>,
        errorSubject: PassthroughSubject<String, Never>,
        postCreatedSubject: PassthroughSubject<Void, Never>
    ) {
        isLoadingSubject.send(true)

        let location = locationManager.locationSubject.value
        let latitude = location?.coordinate.latitude ?? 0.0
        let longitude = location?.coordinate.longitude ?? 0.0

        if postData.mediaItems.isEmpty {
            submitPost(
                postData: postData,
                fileUrls: [],
                latitude: latitude,
                longitude: longitude,
                isLoadingSubject: isLoadingSubject,
                errorSubject: errorSubject,
                postCreatedSubject: postCreatedSubject
            )
        } else {
            uploadMediaFiles(
                mediaItems: postData.mediaItems,
                postData: postData,
                latitude: latitude,
                longitude: longitude,
                isLoadingSubject: isLoadingSubject,
                errorSubject: errorSubject,
                postCreatedSubject: postCreatedSubject
            )
        }
    }

    private func uploadMediaFiles(
        mediaItems: [CommunityPostMediaItem],
        postData: PostData,
        latitude: Double,
        longitude: Double,
        isLoadingSubject: CurrentValueSubject<Bool, Never>,
        errorSubject: PassthroughSubject<String, Never>,
        postCreatedSubject: PassthroughSubject<Void, Never>
    ) {
        let files = mediaItems.compactMap { item -> CommunityPostAPI.UploadFileRequest? in
            switch item.kind {
            case .image(let image):
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                let fileName = "image_\(UUID().uuidString).jpg"
                return CommunityPostAPI.UploadFileRequest(data: data, fileName: fileName, mimeType: "image/jpeg")
            case .video(let thumbnail):
                guard let data = thumbnail.jpegData(compressionQuality: 0.8) else { return nil }
                let fileName = "video_\(UUID().uuidString).jpg"
                return CommunityPostAPI.UploadFileRequest(data: data, fileName: fileName, mimeType: "video/mp4")
            }
        }

        postRepository.uploadPostFiles(files: files)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        isLoadingSubject.send(false)
                        errorSubject.send("이미지/영상 파일을 업로드하는데 실패했습니다")
                    }
                },
                receiveValue: { [weak self] fileUrls in
                    self?.submitPost(
                        postData: postData,
                        fileUrls: fileUrls,
                        latitude: latitude,
                        longitude: longitude,
                        isLoadingSubject: isLoadingSubject,
                        errorSubject: errorSubject,
                        postCreatedSubject: postCreatedSubject
                    )
                }
            )
            .store(in: &cancellables)
    }

    private func submitPost(
        postData: PostData,
        fileUrls: [String],
        latitude: Double,
        longitude: Double,
        isLoadingSubject: CurrentValueSubject<Bool, Never>,
        errorSubject: PassthroughSubject<String, Never>,
        postCreatedSubject: PassthroughSubject<Void, Never>
    ) {
        let request = CommunityPostCreateRequest(
            category: postData.category,
            title: postData.title,
            content: postData.content,
            storeId: postData.storeId,
            latitude: latitude,
            longitude: longitude,
            files: fileUrls
        )

        postRepository.createPost(request: request)
        .sink(
            receiveCompletion: { completion in
                isLoadingSubject.send(false)
                if case .failure(let error) = completion {
                    errorSubject.send(error.errorDescription)
                }
            },
            receiveValue: { [weak self] _ in
                self?.onPostCreated?()
                postCreatedSubject.send()
            }
        )
        .store(in: &cancellables)
    }
}

extension Publisher {
    func withLatestFrom<Other: Publisher>(_ other: Other) -> AnyPublisher<Other.Output, Failure> where Other.Failure == Failure {
        let upstream = self
        return other
            .map { second in upstream.map { _ in second } }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
