//
//  ChatCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit

protocol ChatCoordinatorDelegate: AnyObject {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator)
}

final class ChatCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: ChatCoordinatorDelegate?

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
