//
//  ProfileViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/22/25.
//

import Foundation
import Combine

final class ProfileViewModel: BaseViewModel, ViewModelType {
    
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
        let logoutSuccess: AnyPublisher<Void, Never>
    }
    
    func transform(input: Input) -> Output {
        let logoutSuccessSubject = PassthroughSubject<Void, Never>()
        
        input.logoutButtonTapped
            .sink { [weak self] _ in
                guard let self else { return }
                performLogout {
                    logoutSuccessSubject.send()
                }
            }
            .store(in: &cancellables)

        return Output(
            logoutError: logoutErrorSubject.eraseToAnyPublisher(),
            logoutSuccess: logoutSuccessSubject.eraseToAnyPublisher()
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
