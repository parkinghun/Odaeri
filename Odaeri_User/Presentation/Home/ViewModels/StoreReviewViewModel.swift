//
//  StoreReviewViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

final class StoreReviewViewModel: BaseViewModel, ViewModelType {
    private enum Constant {
        static let pageLimit = 10
    }

    weak var coordinator: HomeCoordinator?

    private let storeId: String
    private let storeName: String
    private let storeImageUrl: String?
    private let repository: StoreReviewRepository

    private var currentOrder: StoreReviewOrder = .latest
    private var nextCursor: String?
    private var isLoadingMore = false
    private var ratingCounts: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
    private var reviews: [StoreReviewEntity] = []
    private var photoUrls: [String] = []

    init(
        storeId: String,
        storeName: String,
        storeImageUrl: String?,
        repository: StoreReviewRepository
    ) {
        self.storeId = storeId
        self.storeName = storeName
        self.storeImageUrl = storeImageUrl
        self.repository = repository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let loadMore: AnyPublisher<Void, Never>
        let orderChanged: AnyPublisher<StoreReviewOrder, Never>
        let editReview: AnyPublisher<StoreReviewItemViewModel, Never>
        let reviewUpdated: AnyPublisher<StoreReviewDetailEntity, Never>
        let deleteReview: AnyPublisher<String, Never>
        let profileTapped: AnyPublisher<StoreReviewProfileTarget, Never>
        let galleryTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let summary: AnyPublisher<StoreReviewSummaryViewModel, Never>
        let reviews: AnyPublisher<[StoreReviewItemViewModel], Never>
        let photoUrls: AnyPublisher<[String], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let summarySubject = CurrentValueSubject<StoreReviewSummaryViewModel, Never>(StoreReviewSummaryViewModel.empty)
        let reviewsSubject = CurrentValueSubject<[StoreReviewItemViewModel], Never>([])
        let photoUrlsSubject = CurrentValueSubject<[String], Never>([])
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadInitial(
                    summarySubject: summarySubject,
                    reviewsSubject: reviewsSubject,
                    photoUrlsSubject: photoUrlsSubject
                )
            }
            .store(in: &cancellables)

        input.orderChanged
            .sink { [weak self] order in
                guard let self else { return }
                self.currentOrder = order
                self.loadInitial(
                    summarySubject: summarySubject,
                    reviewsSubject: reviewsSubject,
                    photoUrlsSubject: photoUrlsSubject
                )
            }
            .store(in: &cancellables)

        input.loadMore
            .sink { [weak self] in
                self?.loadMoreReviews(
                    reviewsSubject: reviewsSubject,
                    photoUrlsSubject: photoUrlsSubject
                )
            }
            .store(in: &cancellables)

        input.deleteReview
            .sink { [weak self] reviewId in
                self?.deleteReview(
                    reviewId: reviewId,
                    summarySubject: summarySubject,
                    reviewsSubject: reviewsSubject,
                    photoUrlsSubject: photoUrlsSubject
                )
            }
            .store(in: &cancellables)

        input.editReview
            .sink { [weak self] item in
                guard let self else { return }
                let context = ReviewWriteContext(
                    storeId: self.storeId,
                    storeName: self.storeName,
                    storeImageUrl: self.storeImageUrl,
                    menuNames: item.menuList,
                    orderCode: nil
                )
                let initial = ReviewWriteInitialData(
                    rating: item.rating,
                    content: item.content,
                    imageUrls: item.imageUrls
                )
                let mode = ReviewWriteMode.edit(
                    context: context,
                    reviewId: item.reviewId,
                    initial: initial
                )
                self.coordinator?.showReviewWrite(mode: mode)
            }
            .store(in: &cancellables)

        input.reviewUpdated
            .sink { [weak self] review in
                self?.applyUpdatedReview(
                    review,
                    summarySubject: summarySubject,
                    reviewsSubject: reviewsSubject,
                    photoUrlsSubject: photoUrlsSubject
                )
            }
            .store(in: &cancellables)

        input.profileTapped
            .sink { [weak self] target in
                guard !target.userId.isEmpty else { return }
                self?.coordinator?.showUserProfile(
                    userId: target.userId,
                    nick: target.nick,
                    profileImage: target.profileImage
                )
            }
            .store(in: &cancellables)

        input.galleryTapped
            .sink { [weak self] in
                guard let self else { return }
                self.coordinator?.showReviewGallery(imageUrls: self.photoUrls)
            }
            .store(in: &cancellables)

        return Output(
            summary: summarySubject.eraseToAnyPublisher(),
            reviews: reviewsSubject.eraseToAnyPublisher(),
            photoUrls: photoUrlsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
}

enum StoreReviewOrder: String, CaseIterable {
    case latest = "latest"
    case rating = "rating"

    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .rating:
            return "평점순"
        }
    }
}

struct StoreReviewSummaryViewModel: Equatable {
    let averageRatingText: String
    let totalCountText: String
    let ratingRows: [StoreReviewRatingRowViewModel]

    static let empty = StoreReviewSummaryViewModel(
        averageRatingText: "0.0",
        totalCountText: "리뷰 0",
        ratingRows: (1...5).reversed().map {
            StoreReviewRatingRowViewModel(rating: $0, count: 0, ratio: 0)
        }
    )
}

struct StoreReviewRatingRowViewModel: Equatable {
    let rating: Int
    let count: Int
    let ratio: Float
}

struct StoreReviewItemViewModel: Hashable {
    let reviewId: String
    let creatorUserId: String
    let creatorName: String
    let creatorProfileUrl: String?
    let rating: Int
    let createdAtText: String
    let content: String
    let menuList: [String]
    let userTotalReviewCount: Int
    let imageUrls: [String]
    let isMe: Bool
}

struct StoreReviewProfileTarget: Hashable {
    let userId: String
    let nick: String
    let profileImage: String?
}

private extension StoreReviewViewModel {
    func loadInitial(
        summarySubject: CurrentValueSubject<StoreReviewSummaryViewModel, Never>,
        reviewsSubject: CurrentValueSubject<[StoreReviewItemViewModel], Never>,
        photoUrlsSubject: CurrentValueSubject<[String], Never>
    ) {
        isLoadingSubject.send(true)
        isLoadingMore = false
        nextCursor = nil
        ratingCounts = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        reviews = []

        let ratingsPublisher = repository.fetchReviewRatings(storeId: storeId)
            .catch { [weak self] error -> AnyPublisher<[ReviewRatingEntity], Never> in
                self?.postError(error)
                return Just([]).eraseToAnyPublisher()
            }

        let reviewsPublisher = repository.fetchReviews(
            storeId: storeId,
            next: nil,
            limit: Constant.pageLimit,
            orderBy: currentOrder.rawValue
        )
        .catch { [weak self] error -> AnyPublisher<StoreReviewListResult, Never> in
            self?.postError(error)
            return Just(StoreReviewListResult(reviews: [], nextCursor: nil)).eraseToAnyPublisher()
        }

        Publishers.Zip(ratingsPublisher, reviewsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratings, listResult in
                guard let self else { return }
                self.updateRatingCounts(with: ratings)
                self.reviews = self.sortedReviews(listResult.reviews)
                self.photoUrls = self.collectPhotoUrls(from: self.reviews)
                photoUrlsSubject.send(self.photoUrls)
                self.nextCursor = self.normalizedCursor(listResult.nextCursor)
                summarySubject.send(self.makeSummary(from: listResult.reviews))
                reviewsSubject.send(self.reviews.map(self.makeReviewItem))
                isLoadingSubject.send(false)
            }
            .store(in: &cancellables)
    }

    func loadMoreReviews(
        reviewsSubject: CurrentValueSubject<[StoreReviewItemViewModel], Never>,
        photoUrlsSubject: CurrentValueSubject<[String], Never>
    ) {
        guard !isLoadingMore, let nextCursor, !nextCursor.isEmpty else { return }
        isLoadingMore = true

        repository.fetchReviews(
            storeId: storeId,
            next: nextCursor,
            limit: Constant.pageLimit,
            orderBy: currentOrder.rawValue
        )
        .catch { [weak self] error -> AnyPublisher<StoreReviewListResult, Never> in
            self?.postError(error)
            return Just(StoreReviewListResult(reviews: [], nextCursor: nil)).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            guard let self else { return }
            self.isLoadingMore = false
            self.nextCursor = self.normalizedCursor(result.nextCursor)
            let existingIds = Set(self.reviews.map { $0.reviewId })
            let newReviews = result.reviews.filter { !existingIds.contains($0.reviewId) }
            self.reviews.append(contentsOf: newReviews)
            self.reviews = self.sortedReviews(self.reviews)
            self.photoUrls = self.collectPhotoUrls(from: self.reviews)
            photoUrlsSubject.send(self.photoUrls)
            reviewsSubject.send(self.reviews.map(self.makeReviewItem))
            isLoadingSubject.send(false)
        }
        .store(in: &cancellables)
    }

    func deleteReview(
        reviewId: String,
        summarySubject: CurrentValueSubject<StoreReviewSummaryViewModel, Never>,
        reviewsSubject: CurrentValueSubject<[StoreReviewItemViewModel], Never>,
        photoUrlsSubject: CurrentValueSubject<[String], Never>
    ) {
        guard let review = reviews.first(where: { $0.reviewId == reviewId }) else { return }
        repository.deleteReview(storeId: storeId, reviewId: reviewId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    self.postError(error)
                }
            } receiveValue: { [weak self] in
                guard let self else { return }
                self.reviews.removeAll { $0.reviewId == reviewId }
                if let current = self.ratingCounts[review.rating] {
                    self.ratingCounts[review.rating] = max(0, current - 1)
                }
                self.photoUrls = self.collectPhotoUrls(from: self.reviews)
                photoUrlsSubject.send(self.photoUrls)
                summarySubject.send(self.makeSummary(from: self.reviews))
                reviewsSubject.send(self.reviews.map(self.makeReviewItem))
            }
            .store(in: &cancellables)
    }

    func applyUpdatedReview(
        _ detail: StoreReviewDetailEntity,
        summarySubject: CurrentValueSubject<StoreReviewSummaryViewModel, Never>,
        reviewsSubject: CurrentValueSubject<[StoreReviewItemViewModel], Never>,
        photoUrlsSubject: CurrentValueSubject<[String], Never>
    ) {
        guard let index = reviews.firstIndex(where: { $0.reviewId == detail.reviewId }) else { return }
        let current = reviews[index]
        if current.rating != detail.rating {
            if let currentCount = ratingCounts[current.rating] {
                ratingCounts[current.rating] = max(0, currentCount - 1)
            }
            ratingCounts[detail.rating, default: 0] += 1
        }

        let updatedReview = StoreReviewEntity(
            reviewId: current.reviewId,
            content: detail.content,
            rating: detail.rating,
            reviewImageUrls: detail.reviewImageUrls,
            orderMenuList: detail.orderMenuList,
            creator: detail.creator,
            userTotalReviewCount: current.userTotalReviewCount,
            userTotalRating: current.userTotalRating,
            createdAt: current.createdAt,
            updatedAt: detail.updatedAt
        )

        reviews[index] = updatedReview
        reviews = sortedReviews(reviews)
        photoUrls = collectPhotoUrls(from: reviews)
        photoUrlsSubject.send(photoUrls)
        summarySubject.send(makeSummary(from: reviews))
        reviewsSubject.send(reviews.map(makeReviewItem))
    }

    func updateRatingCounts(with ratings: [ReviewRatingEntity]) {
        var merged = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        ratings.forEach { entity in
            merged[entity.rating] = entity.count
        }
        ratingCounts = merged
    }

    func makeSummary(from reviews: [StoreReviewEntity]) -> StoreReviewSummaryViewModel {
        let totalCount = ratingCounts.values.reduce(0, +)
        let average = makeAverageRating(from: reviews, totalCount: totalCount)
        let maxCount = ratingCounts.values.max() ?? 0

        let rows = (1...5).reversed().map { rating -> StoreReviewRatingRowViewModel in
            let count = ratingCounts[rating] ?? 0
            let ratio = maxCount > 0 ? Float(count) / Float(maxCount) : 0
            return StoreReviewRatingRowViewModel(rating: rating, count: count, ratio: ratio)
        }

        return StoreReviewSummaryViewModel(
            averageRatingText: String(format: "%.1f", average),
            totalCountText: "리뷰 \(totalCount)",
            ratingRows: rows
        )
    }

    func makeAverageRating(from reviews: [StoreReviewEntity], totalCount: Int) -> Double {
        guard totalCount > 0 else { return 0 }
        let sum = ratingCounts.reduce(0) { partial, element in
            partial + (element.key * element.value)
        }
        return Double(sum) / Double(totalCount)
    }

    func makeReviewItem(from entity: StoreReviewEntity) -> StoreReviewItemViewModel {
        let menuList = entity.orderMenuList.isEmpty ? ["메뉴 정보 없음"] : entity.orderMenuList
        let createdAtText = entity.createdAt?.toRelativeTime ?? "방금 전"
        return StoreReviewItemViewModel(
            reviewId: entity.reviewId,
            creatorUserId: entity.creator.userId,
            creatorName: entity.creator.nick,
            creatorProfileUrl: entity.creator.profileImage,
            rating: entity.rating,
            createdAtText: createdAtText,
            content: entity.content,
            menuList: menuList,
            userTotalReviewCount: entity.userTotalReviewCount,
            imageUrls: entity.reviewImageUrls,
            isMe: entity.isMe
        )
    }

    func postError(_ error: NetworkError) {
        errorSubject.send(error.errorDescription)
    }

    func normalizedCursor(_ cursor: String?) -> String? {
        guard let cursor, !cursor.isEmpty, cursor != "0" else { return nil }
        return cursor
    }

    func collectPhotoUrls(from reviews: [StoreReviewEntity]) -> [String] {
        reviews.flatMap { $0.reviewImageUrls }
    }

    func sortedReviews(_ reviews: [StoreReviewEntity]) -> [StoreReviewEntity] {
        switch currentOrder {
        case .latest:
            return reviews.sorted {
                let leftDate = $0.updatedAt ?? $0.createdAt ?? .distantPast
                let rightDate = $1.updatedAt ?? $1.createdAt ?? .distantPast
                if leftDate == rightDate {
                    return $0.reviewId > $1.reviewId
                }
                return leftDate > rightDate
            }
        case .rating:
            return reviews.sorted {
                if $0.rating == $1.rating {
                    let leftDate = $0.updatedAt ?? $0.createdAt ?? .distantPast
                    let rightDate = $1.updatedAt ?? $1.createdAt ?? .distantPast
                    if leftDate == rightDate {
                        return $0.reviewId > $1.reviewId
                    }
                    return leftDate > rightDate
                }
                return $0.rating > $1.rating
            }
        }
    }
}
