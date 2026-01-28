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

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let communityViewModel = CommunityViewModel(
            postRepository: CommunityPostRepositoryImpl(),
            bannerRepository: BannerRepositoryImpl()
        )
        communityViewModel.coordinator = self
        let communityViewController = CommunityViewController(viewModel: communityViewModel)
        navigationController.setViewControllers([communityViewController], animated: false)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(
            path: path,
            bannerRepository: BannerRepositoryImpl()
        )
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(
            storeId: storeId,
            storeRepository: StoreRepositoryImpl(),
            orderRepository: OrderRepositoryImpl()
        )
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showUserProfile(userId: String) {
        let videoRepository = VideoRepositoryImpl()
        let viewModel = UserProfileViewModel(
            targetUserId: userId,
            communityRepository: CommunityPostRepositoryImpl(),
            chatRepository: ChatRepositoryImpl(),
            userRepository: UserRepositoryImpl(),
            getSavedVideoIdsUseCase: DefaultGetSavedVideoIdsUseCase(),
            getVideoListUseCase: DefaultGetVideoListUseCase(repository: videoRepository)
        )
        viewModel.coordinator = self
        let viewController = UserProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showPostDetail(postId: String) {
        let viewModel = CommunityPostDetailViewModel(
            postId: postId,
            postRepository: CommunityPostRepositoryImpl(),
            commentRepository: CommunityCommentRepositoryImpl()
        )
        viewModel.coordinator = self
        let viewController = CommunityPostDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChat() {
        let chatCoordinator = ChatCoordinator(navigationController: navigationController)
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.start()
    }

    func showStoreSearch() {
        let viewModel = StoreSearchViewModel(
            viewType: .community,
            storeRepository: StoreRepositoryImpl(),
            orderRepository: OrderRepositoryImpl()
        )
        let viewController = StoreSearchViewController(viewModel: viewModel, viewType: .community)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func openWritePost() {
        let viewModel = CommunityPostViewModel(postRepository: CommunityPostRepositoryImpl())
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
            postRepository: CommunityPostRepositoryImpl()
        )
        viewModel.coordinator = self
        let viewController = CommunityPostViewController(viewType: .edit, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChatRoom(roomId: String, title: String?) {
        let chatCoordinator = ChatCoordinator(navigationController: navigationController)
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.showChatRoom(roomId: roomId, title: title)
    }

    func showSavedVideo(videoId: String) {
        let repository = VideoRepositoryImpl()
        let useCase = DefaultGetVideoListUseCase(repository: repository)

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

                let getStreamURLUseCase = DefaultGetVideoStreamURLUseCase(repository: repository)
                let toggleVideoLikeUseCase = DefaultToggleVideoLikeUseCase(repository: repository)
                let toggleSaveVideoUseCase = DefaultToggleSaveVideoUseCase()
                let checkVideoSavedUseCase = DefaultCheckVideoSavedUseCase()
                let viewModel = StreamingDetailViewModel(
                    video: video,
                    getStreamURLUseCase: getStreamURLUseCase,
                    toggleVideoLikeUseCase: toggleVideoLikeUseCase,
                    toggleSaveVideoUseCase: toggleSaveVideoUseCase,
                    checkVideoSavedUseCase: checkVideoSavedUseCase
                )
                let playerManager = StreamingPlayerManager(videoRepository: repository)
                let viewController = StreamingDetailViewController(
                    video: video,
                    viewModel: viewModel,
                    playerManager: playerManager
                )

                let streamingCoordinator = StreamingCoordinator(navigationController: self.navigationController)
                self.addChild(streamingCoordinator)
                viewController.coordinator = streamingCoordinator

                self.navigationController.pushViewController(viewController, animated: true)
            }
            .store(in: &cancellables)
    }

    func didFinishLogout() {
        TokenManager.shared.clearTokens()
        UserManager.shared.clearUser()
        NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
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
            let storeRepository = StoreRepositoryImpl()
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
