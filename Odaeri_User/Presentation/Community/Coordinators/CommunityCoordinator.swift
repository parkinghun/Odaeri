//
//  CommunityCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import Combine

protocol CommunityCoordinatorDelegate: AnyObject {
    func communityCoordinatorDidCreatePost(_ coordinator: CommunityCoordinator)
}

final class CommunityCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: CommunityCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let communityViewModel = CommunityViewModel(
            postRepository: dependencies.communityPostRepository,
            bannerRepository: dependencies.bannerRepository,
            locationManager: dependencies.locationManager,
            routeManager: dependencies.routeManager,
            notificationCenter: dependencies.notificationCenter,
            userManager: dependencies.userManager
        )
        communityViewModel.coordinator = self
        let communityViewController = CommunityViewController(
            viewModel: communityViewModel,
            chatLocalStore: dependencies.chatLocalStore,
            appMediaService: dependencies.appMediaService
        )
        navigationController.setViewControllers([communityViewController], animated: false)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(
            path: path,
            bannerRepository: dependencies.bannerRepository,
            attendanceService: dependencies.attendanceService,
            webViewManager: dependencies.webViewManager
        )
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(
            storeId: storeId,
            storeRepository: dependencies.storeRepository,
            orderRepository: dependencies.orderRepository,
            locationManager: dependencies.locationManager,
            routeManager: dependencies.routeManager
        )
        let viewController = ShopDetailViewController(
            viewModel: viewModel,
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

    func showPostDetail(postId: String) {
        let viewModel = CommunityPostDetailViewModel(
            postId: postId,
            postRepository: dependencies.communityPostRepository,
            commentRepository: dependencies.communityCommentRepository,
            userManager: dependencies.userManager,
            notificationCenter: dependencies.notificationCenter
        )
        viewModel.coordinator = self
        let viewController = CommunityPostDetailViewController(
            viewModel: viewModel,
            notificationCenter: dependencies.notificationCenter,
            appMediaService: dependencies.appMediaService,
            userManager: dependencies.userManager
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChat() {
        let chatCoordinator = ChatCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.start()
    }

    func showStoreSearch() {
        let viewModel = StoreSearchViewModel(
            viewType: .community,
            storeRepository: dependencies.storeRepository,
            orderRepository: dependencies.orderRepository,
            locationManager: dependencies.locationManager,
            routeManager: dependencies.routeManager
        )
        let viewController = StoreSearchViewController(viewModel: viewModel, viewType: .community)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func openWritePost() {
        let viewModel = CommunityPostViewModel(
            postToEdit: nil,
            locationManager: dependencies.locationManager,
            backgroundManager: dependencies.postBackgroundManager,
            postRepository: dependencies.communityPostRepository
        )
        viewModel.coordinator = self
        let viewController = CommunityPostViewController(viewType: .create, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func didFinishCreatePost() {
        navigationController.popViewController(animated: true)
        delegate?.communityCoordinatorDidCreatePost(self)
    }
}

extension CommunityCoordinator: UserProfileCoordinating {
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
        openWritePost()
    }

    func showEditPost(postId: String) {
        showPlaceholderAlert(title: "게시글 수정", message: "ViewModel에서 호출해주세요")
    }

    func openEditPost(with post: CommunityPostEntity) {
        let viewModel = CommunityPostViewModel(
            postToEdit: post,
            locationManager: dependencies.locationManager,
            backgroundManager: dependencies.postBackgroundManager,
            postRepository: dependencies.communityPostRepository
        )
        viewModel.coordinator = self
        let viewController = CommunityPostViewController(viewType: .edit, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChatRoom(roomId: String, title: String?) {
        let chatCoordinator = ChatCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.showChatRoom(roomId: roomId, title: title)
    }

    func showSavedVideo(videoId: String) {
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

extension CommunityCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        removeChild(coordinator)
    }
}

extension CommunityCoordinator: StoreSearchDelegate {
    func didSelectStore(storeId: String) {
        navigationController.popViewController(animated: true)

        if let postVC = navigationController.viewControllers.last as? CommunityPostViewController {
            let storeRepository = dependencies.storeRepository
            var cancellable: AnyCancellable?

            cancellable = storeRepository.fetchStoreDetail(storeId: storeId)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to fetch store detail: \(error)")
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { store in
                        postVC.updateSelectedStore(id: store.storeId, name: store.name)
                    }
                )
        }
    }
}
