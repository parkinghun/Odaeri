//
//  HomeCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import MapKit
import Combine

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSelectStore(_ coordinator: HomeCoordinator, storeId: String)
}

final class HomeCoordinator: Coordinator, ReviewWriteCoordinating {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: HomeCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        let homeViewModel = HomeViewModel()
        homeViewModel.coordinator = self
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        navigationController.setViewControllers([homeViewController], animated: false)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePendingPaymentValidated(_:)),
            name: .pendingPaymentValidated,
            object: nil
        )
    }

    @objc private func handlePendingPaymentValidated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let info = userInfo["info"] as? PendingPaymentValidatedInfo else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showPendingPaymentSuccessAlert(info: info)
        }
    }

    private func showPendingPaymentSuccessAlert(info: PendingPaymentValidatedInfo) {
        let message: String
        if info.count == 1 {
            message = "\(info.storeName) 가게 결제가 최종 완료되었습니다."
        } else {
            message = "\(info.storeName) 외 \(info.count - 1)개 가게의 결제가 최종 완료되었습니다."
        }

        let alert = UIAlertController(
            title: "결제 확인 완료",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(storeId: storeId)
        viewModel.coordinator = self
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreReviews(storeId: String, storeName: String, storeImageUrl: String?) {
        let viewModel = StoreReviewViewModel(
            storeId: storeId,
            storeName: storeName,
            storeImageUrl: storeImageUrl
        )
        viewModel.coordinator = self
        let viewController = StoreReviewViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showReviewGallery(imageUrls: [String]) {
        let viewController = StoreReviewGalleryViewController(imageUrls: imageUrls)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showReviewWrite(mode: ReviewWriteMode) {
        let viewModel = ReviewWriteViewModel(mode: mode)
        viewModel.coordinator = self
        let viewController = ReviewWriteViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func popReviewWrite() {
        navigationController.popViewController(animated: true)
    }

    func showUserProfile(userId: String, nick: String? = nil, profileImage: String? = nil) {
        let viewModel = UserProfileViewModel(
            targetUserId: userId,
            initialNick: nick,
            initialProfileImage: profileImage
        )
        viewModel.coordinator = self
        let viewController = UserProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(path: path)
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreSearch(with keyword: String? = nil) {
        let viewModel = StoreSearchViewModel(viewType: .home, initialSearchQuery: keyword)
        let viewController = StoreSearchViewController(viewModel: viewModel, viewType: .home)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func showPayment(paymentRequest: PaymentRequest) {
        let paymentCoordinator = PaymentCoordinator(
            navigationController: navigationController,
            paymentRequest: paymentRequest
        )
        paymentCoordinator.delegate = self
        addChild(paymentCoordinator)
        paymentCoordinator.start()
    }

    func showNavigation(route: MKRoute, destination: StoreEntity) {
        let navigationCoordinator = NavigationCoordinator(
            navigationController: navigationController,
            route: route,
            destination: destination
        )
        navigationCoordinator.delegate = self
        addChild(navigationCoordinator)
        navigationCoordinator.start()
    }
}

extension HomeCoordinator: UserProfileCoordinating {
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

    func didFinishLogout() {
        showPlaceholderAlert(title: "로그아웃", message: "로그아웃 처리는 준비 중입니다.")
    }

    private func showPlaceholderAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension HomeCoordinator: PaymentCoordinatorDelegate {
    func paymentCoordinatorDidFinishPayment(_ coordinator: PaymentCoordinator, orderCode: String) {
        removeChild(coordinator)
        showAlert(title: "주문 완료", message: "주문번호: \(orderCode)")
    }

    func paymentCoordinatorDidCancelPayment(_ coordinator: PaymentCoordinator) {
        removeChild(coordinator)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension HomeCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        removeChild(coordinator)
    }
}

extension HomeCoordinator: NavigationCoordinatorDelegate {
    func navigationCoordinatorDidCancel(_ coordinator: NavigationCoordinator) {
        removeChild(coordinator)
    }

    func navigationCoordinatorDidArrive(_ coordinator: NavigationCoordinator, at store: StoreEntity) {
        removeChild(coordinator)
        showAlert(title: "도착", message: "\(store.name)에 도착했습니다.")
    }
}

extension HomeCoordinator: StoreSearchDelegate {
    func didSelectStore(storeId: String) {
        showStoreDetail(storeId: storeId)
    }
}
