//
//  AdminLoginViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

final class AdminLoginViewModel {
    struct Input {
        let emailText: AnyPublisher<String, Never>
        let passwordText: AnyPublisher<String, Never>
        let loginTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let emailValidationMessage: AnyPublisher<String, Never>
        let passwordValidationMessage: AnyPublisher<String, Never>
        let isLoginEnabled: AnyPublisher<Bool, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let loginError: AnyPublisher<String, Never>
        let loginSuccess: AnyPublisher<Void, Never>
    }

    private let authService: AdminAuthService
    private let currentEmail = CurrentValueSubject<String, Never>("")
    private let currentPassword = CurrentValueSubject<String, Never>("")
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let loginErrorSubject = PassthroughSubject<String, Never>()
    private let loginSuccessSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(authService: AdminAuthService = AdminAuthService()) {
        self.authService = authService
    }

    func transform(input: Input) -> Output {
        input.emailText
            .sink { [weak self] email in
                self?.currentEmail.send(email)
            }
            .store(in: &cancellables)

        input.passwordText
            .sink { [weak self] password in
                self?.currentPassword.send(password)
            }
            .store(in: &cancellables)

        let emailValidation = input.emailText
            .map { email in
                InputValidator.emailValidationMessage(for: email) ?? ""
            }
            .eraseToAnyPublisher()

        let passwordValidation = input.passwordText
            .map { password in
                InputValidator.passwordValidationMessage(for: password) ?? ""
            }
            .eraseToAnyPublisher()

        let isLoginEnabled = Publishers.CombineLatest3(
            input.emailText.map { InputValidator.validateEmail($0) },
            input.passwordText.map { InputValidator.validatePassword($0) },
            isLoadingSubject
        )
        .map { emailValid, passwordValid, isLoading in
            emailValid && passwordValid && !isLoading
        }
        .eraseToAnyPublisher()

        input.loginTapped
            .sink { [weak self] in
                self?.performLogin()
            }
            .store(in: &cancellables)

        return Output(
            emailValidationMessage: emailValidation,
            passwordValidationMessage: passwordValidation,
            isLoginEnabled: isLoginEnabled,
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            loginError: loginErrorSubject.eraseToAnyPublisher(),
            loginSuccess: loginSuccessSubject.eraseToAnyPublisher()
        )
    }
}
private extension AdminLoginViewModel {
    func performLogin() {
        let email = currentEmail.value
        let password = currentPassword.value

        guard let deviceToken = TokenManager.shared.deviceToken else {
            loginErrorSubject.send("디바이스 토큰이 없습니다. 앱을 재시작해주세요.")
            return
        }

        isLoadingSubject.send(true)
        authService.emailLogin(email: email, password: password, deviceToken: deviceToken)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.loginErrorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] userResult in
                    TokenManager.shared.saveTokens(
                        accessToken: userResult.accessToken,
                        refreshToken: userResult.refreshToken
                    )
                    let user = UserEntity(from: userResult)
                    UserManager.shared.saveUser(user)
                    self?.loginSuccessSubject.send(())
                }
            )
            .store(in: &cancellables)
    }
}
