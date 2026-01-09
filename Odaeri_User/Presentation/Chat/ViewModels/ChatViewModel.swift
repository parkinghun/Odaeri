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

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let didPop: AnyPublisher<Void, Never>
    }

    struct Output {
    }

    func transform(input: Input) -> Output {
        input.didPop
            .sink { [weak self] _ in
                self?.coordinator?.finish()
            }
            .store(in: &cancellables)

        return Output()
    }
}
