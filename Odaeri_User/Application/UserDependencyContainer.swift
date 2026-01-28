//
//  UserDependencyContainer.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation

final class UserDependencyContainer {
    let tokenManager: TokenManager = .shared
    let userManager: UserManager = .shared
    let notificationCenter: NotificationCenter = .default
    let webViewManager: WebViewManaging = WebViewManager.shared
    let locationManager: LocationManaging = LocationManager.shared
    let routeManager: RouteManaging = RouteManager.shared
    let liveActivityManager: LiveActivityManager = .shared
    let networkMonitor: NetworkMonitor = .shared
    let chatSocketService: ChatSocketService = .shared
    let chatRoomContextManager: ChatRoomContextManager = .shared
    let chatLocalStore: ChatLocalStoreProviding = RealmChatRepository.shared
    let mediaUploadManager: MediaUploadManager = .shared
    let appMediaService: AppMediaService = .shared
    let navigationService: NavigationService = .shared
    let paymentService: PaymentServicing = PaymentService.shared
    let attendanceService: AttendanceServiceProtocol = AttendanceService.shared
    let postBackgroundManager: PostBackgroundManager = .shared

    lazy var userRepository: UserRepository = UserRepositoryImpl()
    lazy var storeRepository: StoreRepository = StoreRepositoryImpl()
    lazy var bannerRepository: BannerRepository = BannerRepositoryImpl()
    lazy var orderRepository: OrderRepository = OrderRepositoryImpl()
    lazy var communityPostRepository: CommunityPostRepository = CommunityPostRepositoryImpl()
    lazy var communityCommentRepository: CommunityCommentRepository = CommunityCommentRepositoryImpl()
    lazy var chatRepository: ChatRepository = ChatRepositoryImpl()
    lazy var storeReviewRepository: StoreReviewRepository = StoreReviewRepositoryImpl()
    lazy var videoRepository: VideoRepository = VideoRepositoryImpl()

    func makeGetVideoListUseCase() -> GetVideoListUseCase {
        DefaultGetVideoListUseCase(repository: videoRepository)
    }

    func makeGetVideoStreamURLUseCase() -> GetVideoStreamURLUseCase {
        DefaultGetVideoStreamURLUseCase(repository: videoRepository)
    }

    func makeToggleVideoLikeUseCase() -> ToggleVideoLikeUseCase {
        DefaultToggleVideoLikeUseCase(repository: videoRepository)
    }

    func makeGetSavedVideoIdsUseCase() -> GetSavedVideoIdsUseCase {
        DefaultGetSavedVideoIdsUseCase()
    }

    func makeToggleSaveVideoUseCase() -> ToggleSaveVideoUseCase {
        DefaultToggleSaveVideoUseCase()
    }

    func makeCheckVideoSavedUseCase() -> CheckVideoSavedUseCase {
        DefaultCheckVideoSavedUseCase()
    }
}
