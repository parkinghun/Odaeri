//
//  ReviewWriteViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation
import Combine
import UIKit
import Moya

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
    private let mediaUploadProvider = MoyaProvider<MediaUploadAPI>()
    weak var coordinator: OrderCoordinator?

    private let ratingSubject: CurrentValueSubject<Int, Never>
    private let contentSubject = CurrentValueSubject<String, Never>("")
    private let imagesSubject = CurrentValueSubject<[UIImage], Never>([])
    private let submitSubject = PassthroughSubject<Void, Never>()

    init(mode: ReviewWriteMode, repository: StoreReviewRepository = StoreReviewRepositoryImpl()) {
        self.mode = mode
        self.repository = repository
        self.ratingSubject = CurrentValueSubject<Int, Never>(mode.initialRating)
    }

    func transform(input: Input) -> Output {
        let mode = self.mode

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

                if images.isEmpty {
                    print("[ReviewWriteVM] Creating review without images")
                    let request = StoreReviewRequest(
                        content: trimmed,
                        rating: rating,
                        imageUrls: [],
                        orderCode: mode.order.orderCode
                    )

                    return self.repository.createReview(
                        storeId: mode.order.store.id,
                        request: request
                    )
                } else {
                    print("[ReviewWriteVM] Uploading \(images.count) images first")
                    return self.uploadImagesAndCreateReview(
                        images: images,
                        rating: rating,
                        content: trimmed
                    )
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

        let multipartData = images.compactMap { image -> MultipartFormData? in
            guard let imageData = image.processForUpload(
                maxDimension: Constant.maxImageDimension,
                compressionQuality: Constant.compressionQuality
            ) else {
                print("[ReviewWriteVM] Failed to process image")
                return nil
            }

            print("[ReviewWriteVM] Image processed: \(imageData.count) bytes")
            return MultipartFormData(
                provider: .data(imageData),
                name: "files",
                fileName: "image_\(UUID().uuidString).jpg",
                mimeType: "image/jpeg"
            )
        }

        guard multipartData.count == images.count else {
            print("[ReviewWriteVM] Image processing failed - expected \(images.count), got \(multipartData.count)")
            return Fail(error: NetworkError.unknown(NSError(
                domain: "ReviewWriteViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        print("[ReviewWriteVM] Uploading \(multipartData.count) images to server")
        return mediaUploadProvider.requestPublisher(
            .storeReviewUpload(storeId: mode.order.store.id, files: multipartData)
        )
        .map { (response: StoreReviewImageUploadResponse) in
            print("[ReviewWriteVM] Images uploaded successfully: \(response.reviewImageUrls)")
            return response.reviewImageUrls
        }
        .flatMap { [weak self] imageUrls -> AnyPublisher<StoreReviewDetailEntity, NetworkError> in
            guard let self = self else {
                return Fail(error: NetworkError.unknown(NSError(domain: "ReviewWriteViewModel", code: -1)))
                    .eraseToAnyPublisher()
            }

            print("[ReviewWriteVM] Creating review with \(imageUrls.count) image URLs")
            let request = StoreReviewRequest(
                content: content,
                rating: rating,
                imageUrls: imageUrls,
                orderCode: self.mode.order.orderCode
            )

            return self.repository.createReview(
                storeId: self.mode.order.store.id,
                request: request
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
        let order = mode.order
        let menuSummary = makeMenuSummary(from: order)
        return ReviewWriteHeader(
            storeName: order.store.name,
            storeImageUrl: order.store.storeImageUrls.first,
            menuSummary: menuSummary
        )
    }

    func makeMenuSummary(from order: OrderListItemEntity) -> String {
        guard let first = order.orderMenuList.first else { return "메뉴 없음" }
        if order.orderMenuList.count > 1 {
            return "\(first.menu.name) 외 \(order.orderMenuList.count - 1)건"
        }
        return first.menu.name
    }
}
