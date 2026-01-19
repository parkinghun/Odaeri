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

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repository = VideoRepositoryImpl()
        let useCase = DefaultGetVideoListUseCase(repository: repository)
        let viewModel = StreamingListViewModel(getVideoListUseCase: useCase)
        viewModel.coordinator = self
        let viewController = StreamingListViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func showVideoDetail(videoId: String) {
        let repository = VideoRepositoryImpl()
        let useCase = DefaultGetVideoStreamURLUseCase(repository: repository)
        let viewModel = StreamingDetailViewModel(
            videoId: videoId,
            getStreamURLUseCase: useCase
        )
        let playerManager = StreamingPlayerManager()
        let viewController = StreamingDetailViewController(viewModel: viewModel, playerManager: playerManager)
        navigationController.pushViewController(viewController, animated: true)
    }
}
