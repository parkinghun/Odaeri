//
//  ChatCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import MapKit

protocol ChatCoordinatorDelegate: AnyObject {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator)
}

final class ChatCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: ChatCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = ChatRoomViewModel(
            chatRepository: dependencies.chatRepository,
            chatLocalStore: dependencies.chatLocalStore,
            userManager: dependencies.userManager
        )
        viewModel.coordinator = self
        let viewController = ChatRoomViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChatRoom(roomId: String, title: String? = nil) {
        let currentUser = dependencies.userManager.currentUser
        let viewModel = ChatViewModel(
            chatRepository: dependencies.chatRepository,
            roomId: roomId,
            currentUserId: currentUser?.userId ?? "",
            mediaUploadManager: dependencies.mediaUploadManager,
            networkMonitor: dependencies.networkMonitor,
            chatLocalStore: dependencies.chatLocalStore,
            chatSocketService: dependencies.chatSocketService,
            userManager: dependencies.userManager,
            currentUserName: currentUser?.nick ?? "나",
            title: title
        )
        viewModel.coordinator = self
        let viewController = ChatViewController(
            viewModel: viewModel,
            chatSocketService: dependencies.chatSocketService,
            chatRoomContextManager: dependencies.chatRoomContextManager,
            chatLocalStore: dependencies.chatLocalStore,
            appMediaService: dependencies.appMediaService,
            notificationCenter: dependencies.notificationCenter
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    func showUserProfile(userId: String) {
        let viewModel = UserProfileViewModel(
            targetUserId: userId,
            communityRepository: dependencies.communityPostRepository,
            chatRepository: dependencies.chatRepository,
            userRepository: dependencies.userRepository,
            getSavedVideoIdsUseCase: dependencies.makeGetSavedVideoIdsUseCase(),
            getVideoListUseCase: dependencies.makeGetVideoListUseCase(),
            userManager: dependencies.userManager,
            tokenManager: dependencies.tokenManager
        )
        viewModel.coordinator = self
        let viewController = UserProfileViewController(
            viewModel: viewModel,
            liveActivityManager: dependencies.liveActivityManager
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    func showSharedVideo(videoId: String) {
        let useCase = self.dependencies.makeGetVideoListUseCase()

        useCase.execute(next: nil, limit: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showPlaceholderAlert(title: "오류", message: error.errorDescription)
                }
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                guard let video = result.videos.first(where: { $0.videoId == videoId }) else {
                    self.showPlaceholderAlert(title: "알림", message: "영상 정보를 찾을 수 없습니다.")
                    return
                }

                let getStreamURLUseCase = self.dependencies.makeGetVideoStreamURLUseCase()
                let toggleVideoLikeUseCase = self.dependencies.makeToggleVideoLikeUseCase()
                let toggleSaveVideoUseCase = self.dependencies.makeToggleSaveVideoUseCase()
                let checkVideoSavedUseCase = self.dependencies.makeCheckVideoSavedUseCase()
                let viewModel = StreamingDetailViewModel(
                    video: video,
                    getStreamURLUseCase: getStreamURLUseCase,
                    toggleVideoLikeUseCase: toggleVideoLikeUseCase,
                    toggleSaveVideoUseCase: toggleSaveVideoUseCase,
                    checkVideoSavedUseCase: checkVideoSavedUseCase
                )
                let playerManager = StreamingPlayerManager(videoRepository: self.dependencies.videoRepository)
                let viewController = StreamingDetailViewController(
                    video: video,
                    viewModel: viewModel,
                    playerManager: playerManager,
                    notificationCenter: self.dependencies.notificationCenter
                )

                let streamingCoordinator = StreamingCoordinator(
                    navigationController: self.navigationController,
                    dependencies: self.dependencies
                )
                self.addChild(streamingCoordinator)
                viewController.coordinator = streamingCoordinator

                self.navigationController.pushViewController(viewController, animated: true)
            }
            .store(in: &cancellables)
    }

    func showImageViewer(
        from viewController: (UIViewController & ImageViewerPresentable),
        imageUrls: [String],
        initialIndex: Int,
        transitionSource: ImageViewerTransitionSource?
    ) {
        viewController.presentImageViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            transitionSource: transitionSource
        )
    }

    func finish() {
        childCoordinators.removeAll()
        delegate?.chatCoordinatorDidFinish(self)
    }
}

extension ChatCoordinator: UserProfileCoordinating {
    func showNavigation(with route: MKRoute, destination: StoreEntity) {
        let navigationCoordinator = NavigationCoordinator(
            navigationController: navigationController,
            route: route,
            destination: destination,
            navigationService: dependencies.navigationService,
            routeManager: dependencies.routeManager
        )
        navigationCoordinator.delegate = self
        addChild(navigationCoordinator)
        navigationCoordinator.start()
    }

    func showEditProfile() {
        showPlaceholderAlert(title: "프로필 수정", message: "프로필 수정 화면은 준비 중입니다.")
    }

    func showSettings() {
        showPlaceholderAlert(title: "설정", message: "설정 화면은 준비 중입니다.")
    }

    func showReportOptions(targetUserId: String) {
        showPlaceholderAlert(title: "신고/차단", message: "신고/차단 기능은 준비 중입니다.")
    }

    func showWritePost() {
        showPlaceholderAlert(title: "글쓰기", message: "글쓰기 화면은 준비 중입니다.")
    }

    func showEditPost(postId: String) {
        showPlaceholderAlert(title: "게시글 수정", message: "게시글 수정 화면은 준비 중입니다.")
    }

    func showSavedVideo(videoId: String) {
        showSharedVideo(videoId: videoId)
    }

    func didFinishLogout() {
        dependencies.tokenManager.clearTokens()
        dependencies.userManager.clearUser()
        dependencies.notificationCenter.post(name: .unauthorizedAccess, object: nil)
    }

    private func showPlaceholderAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension ChatCoordinator: NavigationCoordinatorDelegate {
    func navigationCoordinatorDidCancel(_ coordinator: NavigationCoordinator) {
        removeChild(coordinator)
    }

    func navigationCoordinatorDidArrive(_ coordinator: NavigationCoordinator, at store: StoreEntity) {
        removeChild(coordinator)
        showPlaceholderAlert(title: "도착", message: "\(store.name)에 도착했습니다.")
    }
}
