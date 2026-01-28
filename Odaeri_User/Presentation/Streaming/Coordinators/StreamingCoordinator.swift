//
//  StreamingCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit

protocol StreamingCoordinatorDelegate: AnyObject {
}

final class StreamingCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: StreamingCoordinatorDelegate?

    private var activePIPPlayerManager: StreamingPlayerManager?
    private var activePIPViewController: StreamingDetailViewController?
    private var activePIPVideo: VideoEntity?

    private let dependencies: UserDependencyContainer

    init(navigationController: UINavigationController, dependencies: UserDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let useCase = dependencies.makeGetVideoListUseCase()
        let viewModel = StreamingListViewModel(getVideoListUseCase: useCase)
        viewModel.coordinator = self
        let viewController = StreamingListViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func showVideoDetail(video: VideoEntity) {
        let getStreamURLUseCase = dependencies.makeGetVideoStreamURLUseCase()
        let toggleVideoLikeUseCase = dependencies.makeToggleVideoLikeUseCase()
        let toggleSaveVideoUseCase = dependencies.makeToggleSaveVideoUseCase()
        let checkVideoSavedUseCase = dependencies.makeCheckVideoSavedUseCase()
        let viewModel = StreamingDetailViewModel(
            video: video,
            getStreamURLUseCase: getStreamURLUseCase,
            toggleVideoLikeUseCase: toggleVideoLikeUseCase,
            toggleSaveVideoUseCase: toggleSaveVideoUseCase,
            checkVideoSavedUseCase: checkVideoSavedUseCase
        )
        let playerManager = StreamingPlayerManager(videoRepository: dependencies.videoRepository)
        let viewController = StreamingDetailViewController(
            video: video,
            viewModel: viewModel,
            playerManager: playerManager,
            notificationCenter: dependencies.notificationCenter
        )
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func presentShareSheet(from presenter: UIViewController, payload: ShareCardPayload) {
        let viewModel = ShareTargetPickerViewModel(
            sharePayload: payload,
            chatRepository: dependencies.chatRepository,
            userRepository: dependencies.userRepository,
            userManager: dependencies.userManager
        )
        let viewController = ShareTargetPickerViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .pageSheet

        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        presenter.present(viewController, animated: true)
    }

    func retainPIPSession(playerManager: StreamingPlayerManager, viewController: StreamingDetailViewController, video: VideoEntity) {
        print("[StreamingCoordinator] Retaining PIP session")
        activePIPPlayerManager = playerManager
        activePIPViewController = viewController
        activePIPVideo = video
    }

    func releasePIPSession() {
        print("[StreamingCoordinator] Releasing PIP session")
        activePIPPlayerManager = nil
        activePIPViewController = nil
        activePIPVideo = nil
    }

    func restorePIPViewController(completionHandler: @escaping (Bool) -> Void) {
        print("[StreamingCoordinator] Restoring PIP view controller")

        guard let existingVC = activePIPViewController else {
            print("[StreamingCoordinator] No PIP session to restore")
            completionHandler(false)
            return
        }

        if navigationController.viewControllers.contains(existingVC) {
            print("[StreamingCoordinator] Existing VC is still in navigation stack, popping to it")
            navigationController.popToViewController(existingVC, animated: false)
        } else {
            print("[StreamingCoordinator] Pushing existing VC back to navigation stack")
            navigationController.pushViewController(existingVC, animated: false)
        }

        completionHandler(true)
    }
}
