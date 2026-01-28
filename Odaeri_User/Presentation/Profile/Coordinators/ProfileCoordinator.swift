//
//  ProfileCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/22/25.
//

import UIKit
import Combine

protocol ProfileCoordinatorDelegate: AnyObject {
    func profileCoordinatorDidFinishLogout(_ coordinator: ProfileCoordinator)
}

final class ProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: ProfileCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let targetUserId = dependencies.userManager.currentUser?.userId ?? ""
        let viewModel = UserProfileViewModel(
            targetUserId: targetUserId,
            communityRepository: dependencies.communityPostRepository,
            chatRepository: dependencies.chatRepository,
            userRepository: dependencies.userRepository,
            getSavedVideoIdsUseCase: dependencies.makeGetSavedVideoIdsUseCase(),
            getVideoListUseCase: dependencies.makeGetVideoListUseCase(),
            userManager: dependencies.userManager,
            tokenManager: dependencies.tokenManager
        )
        viewModel.coordinator = self
        let viewController = UserProfileViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func didFinishLogout() {
        delegate?.profileCoordinatorDidFinishLogout(self)
    }

    func showEditProfile() {
        let viewModel = UserProfileEditViewModel(
            userRepository: dependencies.userRepository,
            userManager: dependencies.userManager
        )
        let viewController = UserProfileEditViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showSettings() {
        showPlaceholderAlert(title: "설정", message: "설정 화면은 준비 중입니다.")
    }

    func showReportOptions(targetUserId: String) {
        showPlaceholderAlert(title: "신고/차단", message: "신고/차단 기능은 준비 중입니다.")
    }

    func showWritePost() {
        showPlaceholderAlert(title: "글쓰기", message: "게시글 작성 화면은 준비 중입니다.")
    }

    func showEditPost(postId: String) {
        showPlaceholderAlert(title: "게시글 수정", message: "게시글 수정 화면은 준비 중입니다.")
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

    private func showPlaceholderAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension ProfileCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        removeChild(coordinator)
    }
}

extension ProfileCoordinator: UserProfileCoordinating {}
