//
//  CommunityCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine

protocol CommunityCoordinatorDelegate: AnyObject {
    func communityCoordinatorDidCreatePost(_ coordinator: CommunityCoordinator)
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

    func showStoreSearch() {
        let viewModel = StoreSearchViewModel(viewType: .community)
        let viewController = StoreSearchViewController(viewModel: viewModel, viewType: .community)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func openWritePost() {
        let viewModel = CommunityPostViewModel()
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
        let viewModel = CommunityPostViewModel(postToEdit: post)
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
