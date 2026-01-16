//
//  CommunityCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

protocol CommunityCoordinatorDelegate: AnyObject {
    
}

final class CommunityCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: CommunityCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let communityViewModel = CommunityViewModel()
        communityViewModel.coordinator = self
        let communityViewController = CommunityViewController(viewModel: communityViewModel)
        navigationController.setViewControllers([communityViewController], animated: false)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(path: path)
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(storeId: storeId)
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showUserProfile(userId: String) {
        let viewModel = UserProfileViewModel(targetUserId: userId)
        viewModel.coordinator = self
        let viewController = UserProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showChat() {
        let chatCoordinator = ChatCoordinator(navigationController: navigationController)
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.start()
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
        showPlaceholderAlert(title: "글쓰기", message: "게시글 작성 화면은 준비 중입니다.")
    }

    func showEditPost(postId: String) {
        showPlaceholderAlert(title: "게시글 수정", message: "게시글 수정 화면은 준비 중입니다.")
    }

    func showChatRoom(roomId: String, title: String?) {
        let chatCoordinator = ChatCoordinator(navigationController: navigationController)
        chatCoordinator.delegate = self
        addChild(chatCoordinator)
        chatCoordinator.showChatRoom(roomId: roomId, title: title)
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
