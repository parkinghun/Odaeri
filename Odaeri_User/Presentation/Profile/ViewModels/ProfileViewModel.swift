//
//  ProfileViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/22/25.
//

import Foundation
import Combine

final class ProfileViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ProfileCoordinator?
    
    private let userRepository: UserRepository
    private let logoutErrorSubject = PassthroughSubject<String, Never>()

    
    init(userRepository: UserRepository = UserRepositoryImpl()) {
        self.userRepository = userRepository
    }
    
    struct Input {
        let logoutButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let logoutError: AnyPublisher<String, Never>
    }
    
    func transform(input: Input) -> Output {
        input.logoutButtonTapped
            .sink { [weak self] _ in
                guard let self else { return }
                performLogout {
                    self.coordinator?.didFinishLogout()
                }
            }
            .store(in: &cancellables)

        return Output(
            logoutError: logoutErrorSubject.eraseToAnyPublisher()
        )
    }

    private func performLogout(completion: @escaping () -> Void) {
        userRepository.logout()
            .sink(
                receiveCompletion: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.logoutErrorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { _ in
                    TokenManager.shared.clearTokens()
                    completion()
                }
            )
            .store(in: &cancellables)
    }
}
