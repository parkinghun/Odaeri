//
//  ChatViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import Foundation
import Combine

final class ChatViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ChatCoordinator?
    private let roomId: String
    let title: String?

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
    }

    init(roomId: String, title: String? = nil) {
        self.roomId = roomId
        self.title = title
    }

    func transform(input: Input) -> Output {
        return Output()
    }
}
