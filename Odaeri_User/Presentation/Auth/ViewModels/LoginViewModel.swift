//
//  LoginViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation
import Combine

final class LoginViewModel: BaseViewModel, ViewModelType {

    struct Input {
        let loginButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let loginSuccess: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let loginSuccess = input.loginButtonTapped
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.performLogin()
            })
            .eraseToAnyPublisher()

        return Output(loginSuccess: loginSuccess)
    }

    private func performLogin() {
        TokenManager.shared.saveTokens(
            accessToken: "temp_access_token",
            refreshToken: "temp_refresh_token"
        )
    }
}
