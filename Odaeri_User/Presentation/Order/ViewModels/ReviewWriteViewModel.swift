//
//  ReviewWriteViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation
import Combine
import UIKit

final class ReviewWriteViewModel: BaseViewModel, ViewModelType {
    private enum Constant {
        static let minSubmitLength = 1
        static let maxImageDimension: CGFloat = 1080
        static let compressionQuality: CGFloat = 0.8
    }

    struct Input {
        let ratingSelected: AnyPublisher<Int, Never>
        let contentChanged: AnyPublisher<String, Never>
        let imagesChanged: AnyPublisher<[UIImage], Never>
        let submitTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let header: AnyPublisher<ReviewWriteHeader, Never>
        let currentRating: AnyPublisher<Int, Never>
        let isSubmitEnabled: AnyPublisher<Bool, Never>
        let reviewCreated: AnyPublisher<StoreReviewDetailEntity, Never>
        let error: AnyPublisher<String, Never>
    }

    let mode: ReviewWriteMode
    private let repository: StoreReviewRepository
    weak var coordinator: ReviewWriteCoordinating?

    private let ratingSubject: CurrentValueSubject<Int, Never>
    private let contentSubject = CurrentValueSubject<String, Never>("")
    private let imagesSubject = CurrentValueSubject<[UIImage], Never>([])
    private let submitSubject = PassthroughSubject<Void, Never>()
    private var existingImageUrls: [String] = []

    init(mode: ReviewWriteMode, repository: StoreReviewRepository) {
        self.mode = mode
        self.repository = repository
        self.ratingSubject = CurrentValueSubject<Int, Never>(mode.initialRating)
        self.existingImageUrls = mode.initialImageUrls
    }

    func setExistingImageUrls(_ urls: [String]) {
        self.existingImageUrls = urls
    }

    func transform(input: Input) -> Output {
        input.ratingSelected
            .sink { [weak self] rating in
                self?.ratingSubject.send(rating)
            }
            .store(in: &cancellables)

        input.contentChanged
            .sink { [weak self] content in
                self?.contentSubject.send(content)
            }
            .store(in: &cancellables)

        input.imagesChanged
            .sink { [weak self] images in
                self?.imagesSubject.send(images)
            }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] in
                self?.submitSubject.send(())
            }
            .store(in: &cancellables)

        let header = Just(makeHeader())
            .eraseToAnyPublisher()

        let isSubmitEnabled = Publishers.CombineLatest(ratingSubject, contentSubject)
            .map { rating, content in
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return rating > 0 && trimmed.count >= Constant.minSubmitLength
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let reviewCreatedSubject = PassthroughSubject<StoreReviewDetailEntity, Never>()
        let errorSubject = PassthroughSubject<String, Never>()

        submitSubject
            .withLatestFrom(Publishers.CombineLatest3(ratingSubject, contentSubject, imagesSubject))
            .flatMap { [weak self] _, combined -> AnyPublisher<StoreReviewDetailEntity, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.unknown(NSError(domain: "ReviewWriteViewModel", code: -1)))
                        .eraseToAnyPublisher()
                }

                let (rating, content, images) = combined
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

                print("[ReviewWriteVM] Submit tapped - rating: \(rating), content length: \(trimmed.count), images: \(images.count)")

                switch self.mode {
                case .create:
                    return self.handleCreateReview(rating: rating, content: trimmed, newImages: images)
                case .edit:
                    return self.handleUpdateReview(rating: rating, content: trimmed, newImages: images)
                }
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[ReviewWriteVM] Error: \(error.errorDescription)")
                        errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] review in
                    print("[ReviewWriteVM] Review created successfully: \(review.reviewId)")
                    reviewCreatedSubject.send(review)

                    DispatchQueue.main.async {
                        self?.coordinator?.popReviewWrite()
                    }
                }
            )
            .store(in: &cancellables)

        return Output(
            header: header,
            currentRating: ratingSubject.eraseToAnyPublisher(),
            isSubmitEnabled: isSubmitEnabled,
            reviewCreated: reviewCreatedSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func uploadImagesAndCreateReview(
        images: [UIImage],
        rating: Int,
        content: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        print("[ReviewWriteVM] Processing \(images.count) images for upload")

        let processedImages = images.compactMap { image -> Data? in
            guard let imageData = image.processForUpload(
                maxDimension: Constant.maxImageDimension,
                compressionQuality: Constant.compressionQuality
            ) else {
                print("[ReviewWriteVM] Failed to process image")
                return nil
            }

            print("[ReviewWriteVM] Image processed: \(imageData.count) bytes")
            return imageData
        }

        guard processedImages.count == images.count else {
            print("[ReviewWriteVM] Image processing failed - expected \(images.count), got \(processedImages.count)")
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        guard let orderCode = mode.orderCode else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "주문 정보가 없습니다."]
            ))).eraseToAnyPublisher()
        }

        print("[ReviewWriteVM] Uploading \(processedImages.count) images to server")
        return repository.uploadReviewImages(storeId: mode.storeId, imageDataList: processedImages)
        .flatMap { [weak self] imageUrls -> AnyPublisher<StoreReviewDetailEntity, NetworkError> in
            guard let self = self else {
                return Fail(error: NetworkError.unknown(NSError(domain: "ReviewWriteViewModel", code: -1)))
                    .eraseToAnyPublisher()
            }

            print("[ReviewWriteVM] Creating review with \(imageUrls.count) image URLs")
            return self.repository.createReview(
                storeId: self.mode.storeId,
                content: content,
                rating: rating,
                imageUrls: imageUrls,
                orderCode: orderCode
            )
        }
        .eraseToAnyPublisher()
    }
}

struct ReviewWriteHeader {
    let storeName: String
    let storeImageUrl: String?
    let menuSummary: String
}

struct ReviewWritePayload {
    let mode: ReviewWriteMode
    let rating: Int
    let content: String
}

private extension ReviewWriteViewModel {
    func makeHeader() -> ReviewWriteHeader {
        return ReviewWriteHeader(
            storeName: mode.storeName,
            storeImageUrl: mode.storeImageUrl,
            menuSummary: mode.menuSummary
        )
    }

    func handleCreateReview(
        rating: Int,
        content: String,
        newImages: [UIImage]
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        guard let orderCode = mode.orderCode else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "주문 정보가 없습니다."]
            ))).eraseToAnyPublisher()
        }

        if newImages.isEmpty {
            print("[ReviewWriteVM] Creating review without images")
            return repository.createReview(
                storeId: mode.storeId,
                content: content,
                rating: rating,
                imageUrls: [],
                orderCode: orderCode
            )
        } else {
            print("[ReviewWriteVM] Uploading \(newImages.count) images first")
            return uploadImagesAndCreateReview(
                images: newImages,
                rating: rating,
                content: content
            )
        }
    }

    func handleUpdateReview(
        rating: Int,
        content: String,
        newImages: [UIImage]
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        guard let reviewId = mode.reviewId else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "리뷰 ID가 없습니다."]
            ))).eraseToAnyPublisher()
        }

        if newImages.isEmpty {
            print("[ReviewWriteVM] Updating review with existing images only")
            return repository.updateReview(
                storeId: mode.storeId,
                reviewId: reviewId,
                content: content,
                rating: rating,
                imageUrls: existingImageUrls
            )
        } else {
            print("[ReviewWriteVM] Uploading \(newImages.count) new images for update")
            return uploadImagesAndUpdateReview(
                reviewId: reviewId,
                images: newImages,
                rating: rating,
                content: content
            )
        }
    }

    func uploadImagesAndUpdateReview(
        reviewId: String,
        images: [UIImage],
        rating: Int,
        content: String
    ) -> AnyPublisher<StoreReviewDetailEntity, NetworkError> {
        print("[ReviewWriteVM] Processing \(images.count) images for upload (update)")

        let processedImages = images.compactMap { image -> Data? in
            guard let imageData = image.processForUpload(
                maxDimension: Constant.maxImageDimension,
                compressionQuality: Constant.compressionQuality
            ) else {
                print("[ReviewWriteVM] Failed to process image")
                return nil
            }

            print("[ReviewWriteVM] Image processed: \(imageData.count) bytes")
            return imageData
        }

        guard processedImages.count == images.count else {
            print("[ReviewWriteVM] Image processing failed - expected \(images.count), got \(processedImages.count)")
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        print("[ReviewWriteVM] Uploading \(processedImages.count) images to server")
        return repository.uploadReviewImages(storeId: mode.storeId, imageDataList: processedImages)
        .flatMap { [weak self] newImageUrls -> AnyPublisher<StoreReviewDetailEntity, NetworkError> in
            guard let self = self else {
                return Fail(error: NetworkError.unknown(NSError(domain: "ReviewWriteViewModel", code: -1)))
                    .eraseToAnyPublisher()
            }

            let allImageUrls = self.existingImageUrls + newImageUrls
            print("[ReviewWriteVM] Updating review with \(allImageUrls.count) total image URLs")

            return self.repository.updateReview(
                storeId: self.mode.storeId,
                reviewId: reviewId,
                content: content,
                rating: rating,
                imageUrls: allImageUrls
            )
        }
        .eraseToAnyPublisher()
    }
}
