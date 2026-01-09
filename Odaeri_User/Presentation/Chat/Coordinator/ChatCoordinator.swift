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
        let viewModel = ChatViewModel()
        viewModel.coordinator = self
        let viewController = ChatRoomViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func finish() {
        childCoordinators.removeAll()
        delegate?.chatCoordinatorDidFinish(self)
    }
}
