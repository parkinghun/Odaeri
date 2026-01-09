//
//  ChatViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine

final class ChatViewController: BaseViewController<ChatViewModel> {
    override var navigationBarHidden: Bool { false }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = viewModel.title ?? "채팅"
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = ChatViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()
        )
        _ = viewModel.transform(input: input)
        viewDidLoadSubject.send(())
    }
}
