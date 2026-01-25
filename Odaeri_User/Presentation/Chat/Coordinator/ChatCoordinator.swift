//
//  ChatCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine

protocol ChatCoordinatorDelegate: AnyObject {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator)
}

final class ChatCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: ChatCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = ChatRoomViewModel()
        viewModel.coordinator = self
        let viewController = ChatRoomViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChatRoom(roomId: String, title: String? = nil) {
        let chatRepository = ChatRepositoryImpl()
        let currentUser = UserManager.shared.currentUser
        let viewModel = ChatViewModel(
            chatRepository: chatRepository,
            roomId: roomId,
            currentUserId: currentUser?.userId ?? "",
            currentUserName: currentUser?.nick ?? "나",
            title: title
        )
        viewModel.coordinator = self
        let viewController = ChatViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showUserProfile(userId: String) {
        let viewModel = UserProfileViewModel(targetUserId: userId)
        viewModel.coordinator = self
        let viewController = UserProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showSharedVideo(videoId: String) {
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
                let viewModel = StreamingDetailViewModel(
                    video: video,
                    getStreamURLUseCase: getStreamURLUseCase,
                    toggleVideoLikeUseCase: toggleVideoLikeUseCase
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
