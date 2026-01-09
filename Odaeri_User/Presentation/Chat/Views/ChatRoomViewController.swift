//
//  ChatViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine

final class ChatRoomViewController: BaseViewController<ChatViewModel> {
    private let didPopSubject = PassthroughSubject<Void, Never>()

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = "채팅"
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            didPopSubject.send(())
        }
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = ChatViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            didPop: didPopSubject.eraseToAnyPublisher()
        )
        _ = viewModel.transform(input: input)
        viewDidLoadSubject.send(())
    }
}
