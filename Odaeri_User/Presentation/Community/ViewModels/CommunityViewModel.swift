//
//  CommunityViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import Foundation
import Combine
import CoreLocation

final class CommunityViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: CommunityCoordinator?

    private let postRepository: CommunityPostRepository
    private let bannerRepository: BannerRepository
    private let locationManager: LocationManager

    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let distanceSelectionSubject = CurrentValueSubject<CommunityDistanceSelection, Never>(
        CommunityDistanceSelection(index: 7, label: "1.1km", maxDistance: 1100)
    )
    private let sortTypeSubject = CurrentValueSubject<CommunitySortType, Never>(.recent)
    private let postsSubject = CurrentValueSubject<[CommunityPostItemViewModel], Never>([])

    private var banners: [BannerEntity] = []
    private var currentBannerIndex: Int = 0
    private var bannerTimer: Timer?
    private let currentBannerIndexSubject = PassthroughSubject<Int, Never>()

    private var currentLocation: CLLocation?
    private var likeSubjects: [String: PassthroughSubject<Bool, Never>] = [:]

    init(
        postRepository: CommunityPostRepository = CommunityPostRepositoryImpl(),
        bannerRepository: BannerRepository = BannerRepositoryImpl(),
        locationManager: LocationManager = .shared
    ) {
        self.postRepository = postRepository
        self.bannerRepository = bannerRepository
        self.locationManager = locationManager
    }

    deinit {
        bannerTimer?.invalidate()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let writeButtonTapped: AnyPublisher<Void, Never>
        let chatButtonTapped: AnyPublisher<Void, Never>
        let storeSelected: AnyPublisher<String, Never>
        let creatorSelected: AnyPublisher<String, Never>
        let distanceIndexSelected: AnyPublisher<Int, Never>
        let sortSelected: AnyPublisher<CommunitySortType, Never>
        let userScrolledBanner: AnyPublisher<Int, Never>
        let bannerSelected: AnyPublisher<BannerEntity, Never>
        let postLikeToggled: AnyPublisher<CommunityPostLikeEvent, Never>
    }
    
    struct Output {
        let distanceSelection: AnyPublisher<CommunityDistanceSelection, Never>
        let sortSelection: AnyPublisher<CommunitySortType, Never>
        let banners: AnyPublisher<[BannerEntity], Never>
        let currentBannerIndex: AnyPublisher<Int, Never>
        let posts: AnyPublisher<[CommunityPostItemViewModel], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }
    
    func transform(input: Input) -> Output {
        let bannersSubject = PassthroughSubject<[BannerEntity], Never>()

        locationManager.locationSubject
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.updateDistanceTexts()
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self else { return }
                self.locationManager.checkPermissionAndStartUpdating()
                self.distanceSelectionSubject.send(self.selectionForIndex(7))
                self.fetchBanners(subject: bannersSubject)
                self.fetchPosts()
            }
            .store(in: &cancellables)

        input.distanceIndexSelected
            .map { [weak self] index -> CommunityDistanceSelection in
                guard let self else { return CommunityDistanceSelection(index: 0, label: "100m", maxDistance: 100) }
                return self.selectionForIndex(index)
            }
            .sink { [weak self] selection in
                self?.distanceSelectionSubject.send(selection)
            }
            .store(in: &cancellables)

        input.sortSelected
            .sink { [weak self] sortType in
                self?.sortTypeSubject.send(sortType)
                self?.fetchPosts()
            }
            .store(in: &cancellables)

        input.chatButtonTapped
            .sink { [weak self] _ in
                self?.coordinator?.showChat()
            }
            .store(in: &cancellables)

        input.writeButtonTapped
            .sink { [weak self] _ in
                self?.coordinator?.showWritePost()
            }
            .store(in: &cancellables)

        input.storeSelected
            .sink { [weak self] storeId in
                self?.coordinator?.showStoreDetail(storeId: storeId)
            }
            .store(in: &cancellables)

        input.creatorSelected
            .sink { [weak self] userId in
                self?.coordinator?.showUserProfile(userId: userId)
            }
            .store(in: &cancellables)

        input.distanceIndexSelected
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchPosts()
            }
            .store(in: &cancellables)

        bannersSubject
            .sink { [weak self] banners in
                self?.banners = banners
                self?.currentBannerIndex = 0
                self?.startBannerTimer()
            }
            .store(in: &cancellables)

        input.userScrolledBanner
            .sink { [weak self] index in
                self?.currentBannerIndex = index
                self?.startBannerTimer()
            }
            .store(in: &cancellables)

        input.postLikeToggled
            .sink { [weak self] event in
                self?.handleLikeToggle(event: event)
            }
            .store(in: &cancellables)

        input.bannerSelected
            .compactMap { banner -> String? in
                guard banner.action.isWebView, let path = banner.action.webViewPath else { return nil }
                return path
            }
            .sink { [weak self] path in
                self?.coordinator?.showEventWeb(path: path)
            }
            .store(in: &cancellables)

        return Output(
            distanceSelection: distanceSelectionSubject.eraseToAnyPublisher(),
            sortSelection: sortTypeSubject.eraseToAnyPublisher(),
            banners: bannersSubject.eraseToAnyPublisher(),
            currentBannerIndex: currentBannerIndexSubject.eraseToAnyPublisher(),
            posts: postsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func selectionForIndex(_ index: Int) -> CommunityDistanceSelection {
        switch index {
        case 0...4:
            let meters = (index + 1) * 100
            return CommunityDistanceSelection(index: index, label: "\(meters)m", maxDistance: meters)
        case 5...9:
            let meters = 500 + (index - 4) * 200
            let label = meters >= 1000 ? String(format: "%.1fkm", Double(meters) / 1000.0) : "\(meters)m"
            return CommunityDistanceSelection(index: index, label: label, maxDistance: meters)
        case 10...14:
            let meters = 2000 + (index - 10) * 500
            let label: String
            if meters % 1000 == 0 {
                label = "\(meters / 1000)km"
            } else {
                label = String(format: "%.1fkm", Double(meters) / 1000.0)
            }
            return CommunityDistanceSelection(index: index, label: label, maxDistance: meters)
        default:
            return CommunityDistanceSelection(index: index, label: "전체", maxDistance: nil)
        }
    }

    private func fetchBanners(subject: PassthroughSubject<[BannerEntity], Never>) {
        bannerRepository.fetchBanners()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { banners in
                    subject.send(banners)
                }
            )
            .store(in: &cancellables)
    }

    func refresh() {
        fetchPosts()
    }

    private func fetchPosts() {
        isLoadingSubject.send(true)

        let selection = distanceSelectionSubject.value
        let sortType = sortTypeSubject.value

        postRepository.fetchPostsByGeolocation(
            category: nil,
            longitude: currentLocation?.coordinate.longitude,
            latitude: currentLocation?.coordinate.latitude,
            maxDistance: selection.maxDistance,
            limit: 20,
            next: nil,
            orderBy: sortType.orderBy
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingSubject.send(false)
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            },
            receiveValue: { [weak self] response in
                guard let self else { return }
                let viewModels = response.posts.map { self.makePostViewModel(from: $0) }
                self.postsSubject.send(viewModels)
            }
        )
        .store(in: &cancellables)
    }

    private func startBannerTimer() {
        bannerTimer?.invalidate()
        guard !banners.isEmpty else { return }

        bannerTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentBannerIndex = (self.currentBannerIndex + 1) % self.banners.count
            self.currentBannerIndexSubject.send(self.currentBannerIndex)
        }
    }

    private func handleLikeToggle(event: CommunityPostLikeEvent) {
        updatePostLike(postId: event.postId, isLiked: event.newState)

        if likeSubjects[event.postId] == nil {
            let subject = PassthroughSubject<Bool, Never>()
            likeSubjects[event.postId] = subject

            subject
                .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
                .sink { [weak self] newState in
                    self?.togglePostLike(postId: event.postId, newState: newState)
                }
                .store(in: &cancellables)
        }

        likeSubjects[event.postId]?.send(event.newState)
    }

    private func togglePostLike(postId: String, newState: Bool) {
        postRepository.toggleLike(postId: postId, status: newState)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.updatePostLike(postId: postId, isLiked: !newState)
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func updatePostLike(postId: String, isLiked: Bool) {
        var updatedPosts = postsSubject.value
        guard let index = updatedPosts.firstIndex(where: { $0.postId == postId }) else { return }

        let current = updatedPosts[index]
        let likeCount = max(0, current.likeCountValue + (isLiked ? 1 : -1))
        updatedPosts[index] = current.updatingLike(isLiked: isLiked, likeCount: likeCount)
        postsSubject.send(updatedPosts)
    }

    private func updateDistanceTexts() {
        guard let location = currentLocation else { return }
        let updatedPosts = postsSubject.value.map { viewModel -> CommunityPostItemViewModel in
            let distanceText = formatDistanceText(from: location, latitude: viewModel.latitude, longitude: viewModel.longitude)
            return viewModel.updatingDistance(text: distanceText)
        }
        postsSubject.send(updatedPosts)
    }

    private func makePostViewModel(from post: CommunityPostEntity) -> CommunityPostItemViewModel {
        let mediaItems = post.files.map { url in
            CommunityMediaItemViewModel(
                url: url,
                thumbnailUrl: nil,
                type: CommunityMediaType.from(url: url)
            )
        }

        let createdAtText = post.createdAt?.toRelativeTime ?? "방금 전"
        let distanceText = formatDistanceText(
            from: currentLocation,
            latitude: post.geolocation.latitude,
            longitude: post.geolocation.longitude
        )

        let storeInfoText = storeInfoText(from: post.store)

        return CommunityPostItemViewModel(
            postId: post.postId,
            storeId: post.store.storeId,
            creatorUserId: post.creator.userId,
            creatorName: post.creator.nick,
            creatorProfileImageUrl: post.creator.profileImage,
            createdAtText: createdAtText,
            title: post.title,
            content: post.content,
            likeCountText: "\(post.likeCount)개",
            distanceText: distanceText,
            likeCountValue: post.likeCount,
            isLiked: post.isLike,
            mediaItems: mediaItems,
            storeName: post.store.name,
            storeInfoText: storeInfoText,
            storeImageUrl: post.store.storeImageUrls.first,
            latitude: post.geolocation.latitude,
            longitude: post.geolocation.longitude
        )
    }

    private func storeInfoText(from store: StoreEntity) -> String {
        if store.address.isEmpty {
            return store.category
        }
        return "\(store.category) · \(store.address)"
    }

    private func formatDistanceText(
        from location: CLLocation?,
        latitude: Double,
        longitude: Double
    ) -> String {
        guard let location else { return "--" }
        let distance = RouteManager.shared.calculateDistance(
            from: location.coordinate,
            to: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )

        if distance >= 1.0 {
            return String(format: "%.1fkm", distance)
        }
        return String(format: "%.0fm", distance * 1000)
    }
}

struct CommunityDistanceSelection {
    let index: Int
    let label: String
    let maxDistance: Int?
}

enum CommunitySortType: CaseIterable {
    case recent
    case likes

    var title: String {
        switch self {
        case .recent: return "최신순"
        case .likes: return "좋아요순"
        }
    }

    var orderBy: String {
        switch self {
        case .recent: return "createdAt"
        case .likes: return "likes"
        }
    }
}

struct CommunityPostLikeEvent {
    let postId: String
    let newState: Bool
}

enum CommunityMediaType {
    case image
    case video

    static func from(url: String) -> CommunityMediaType {
        let lowercased = url.lowercased()
        let videoExtensions = [".mp4", ".mov", ".m4v", ".avi"]
        if videoExtensions.contains(where: { lowercased.contains($0) }) {
            return .video
        }
        return .image
    }
}

struct CommunityMediaItemViewModel: Hashable {
    let url: String
    let thumbnailUrl: String?
    let type: CommunityMediaType
}

struct CommunityPostItemViewModel: Hashable {
    let postId: String
    let storeId: String
    let creatorUserId: String
    let creatorName: String
    let creatorProfileImageUrl: String?
    let createdAtText: String
    let title: String
    let content: String
    let likeCountText: String
    let distanceText: String
    let likeCountValue: Int
    let isLiked: Bool
    let mediaItems: [CommunityMediaItemViewModel]
    let storeName: String
    let storeInfoText: String
    let storeImageUrl: String?
    let latitude: Double
    let longitude: Double

    func updatingLike(isLiked: Bool, likeCount: Int) -> CommunityPostItemViewModel {
        CommunityPostItemViewModel(
            postId: postId,
            storeId: storeId,
            creatorUserId: creatorUserId,
            creatorName: creatorName,
            creatorProfileImageUrl: creatorProfileImageUrl,
            createdAtText: createdAtText,
            title: title,
            content: content,
            likeCountText: "\(likeCount)개",
            distanceText: distanceText,
            likeCountValue: likeCount,
            isLiked: isLiked,
            mediaItems: mediaItems,
            storeName: storeName,
            storeInfoText: storeInfoText,
            storeImageUrl: storeImageUrl,
            latitude: latitude,
            longitude: longitude
        )
    }

    func updatingDistance(text: String) -> CommunityPostItemViewModel {
        CommunityPostItemViewModel(
            postId: postId,
            storeId: storeId,
            creatorUserId: creatorUserId,
            creatorName: creatorName,
            creatorProfileImageUrl: creatorProfileImageUrl,
            createdAtText: createdAtText,
            title: title,
            content: content,
            likeCountText: likeCountText,
            distanceText: text,
            likeCountValue: likeCountValue,
            isLiked: isLiked,
            mediaItems: mediaItems,
            storeName: storeName,
            storeInfoText: storeInfoText,
            storeImageUrl: storeImageUrl,
            latitude: latitude,
            longitude: longitude
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(postId)
    }

    static func == (lhs: CommunityPostItemViewModel, rhs: CommunityPostItemViewModel) -> Bool {
        lhs.postId == rhs.postId
    }
}
