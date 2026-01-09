//
//  LoginViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation
import Combine

final class LoginViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: AuthCoordinator?

    private let repository: UserRepository
    private let currentEmail = CurrentValueSubject<String, Never>("")
    private let currentPassword = CurrentValueSubject<String, Never>("")
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let loginErrorSubject = PassthroughSubject<String, Never>()

    init(repository: UserRepository = UserRepositoryImpl()) {
        self.repository = repository
    }

    struct Input {
        let emailText: AnyPublisher<String, Never>
        let passwordText: AnyPublisher<String, Never>
        let loginButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let isEmailValid: AnyPublisher<Bool, Never>
        let isPasswordValid: AnyPublisher<Bool, Never>
        let emailValidationMessage: AnyPublisher<String, Never>
        let passwordValidationMessage: AnyPublisher<String, Never>
        let isLoginEnabled: AnyPublisher<Bool, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let loginError: AnyPublisher<String, Never>
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

        let isEmailValid = input.emailText
            .map { [weak self] email in
                guard let self else { return false }
                return validateEmail(email)
            }
            .eraseToAnyPublisher()

        let isPasswordValid = input.passwordText
            .map { [weak self] password in
                guard let self else { return false }
                return validatePassword(password)
            }
            .eraseToAnyPublisher()

        let emailValidation = input.emailText
            .map { [weak self] email in
                guard let self else { return "" }
                return emailValidationMessage(for: email) ?? ""
            }
            .eraseToAnyPublisher()

        let passwordValidation = input.passwordText
            .map { [weak self] password in
                guard let self else { return "" }
                return passwordValidationMessage(for: password) ?? ""
            }
            .eraseToAnyPublisher()

        let isLoginEnabled = Publishers.CombineLatest3(
            isEmailValid,
            isPasswordValid,
            isLoadingSubject
        )
        .map { emailValid, passwordValid, isLoading in
            emailValid && passwordValid && !isLoading
        }
        .eraseToAnyPublisher()

        input.loginButtonTapped
            .sink { [weak self] _ in
                self?.performLogin(completion: {
                    self?.coordinator?.didFinishLogin()
                })
            }
            .store(in: &cancellables)

        return Output(
            isEmailValid: isEmailValid,
            isPasswordValid: isPasswordValid,
            emailValidationMessage: emailValidation,
            passwordValidationMessage: passwordValidation,
            isLoginEnabled: isLoginEnabled,
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            loginError: loginErrorSubject.eraseToAnyPublisher()
        )
    }

    private func performLogin(completion: @escaping () -> Void) {
        let email = currentEmail.value
        let password = currentPassword.value

        guard let deviceToken = TokenManager.shared.deviceToken else {
            loginErrorSubject.send("디바이스 토큰이 없습니다. 앱을 재시작해주세요.")
            return
        }

        isLoadingSubject.send(true)

        repository.emailLogin(email: email, password: password, deviceToken: deviceToken)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoadingSubject.send(false)

                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.loginErrorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { userResult in
                    TokenManager.shared.saveTokens(
                        accessToken: userResult.accessToken,
                        refreshToken: userResult.refreshToken
                    )

                    let user = UserEntity(from: userResult)
                    UserManager.shared.saveUser(user)

                    completion()
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Validation

private extension LoginViewModel {
    func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }

        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func validatePassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialCharacter = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil

        return hasLetter && hasNumber && hasSpecialCharacter
    }

    func emailValidationMessage(for email: String) -> String? {
        guard !email.isEmpty else { return nil }
        return validateEmail(email) ? nil : "유효한 이메일 형식이 아닙니다 (예: user@example.com)"
    }

    func passwordValidationMessage(for password: String) -> String? {
        guard !password.isEmpty else { return nil }

        if password.count < 8 {
            return "비밀번호는 최소 8자 이상이어야 합니다"
        }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialCharacter = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil

        if !hasLetter {
            return "영문자를 1개 이상 포함해야 합니다"
        }

        if !hasNumber {
            return "숫자를 1개 이상 포함해야 합니다"
        }

        if !hasSpecialCharacter {
            return "특수문자(@$!%*#?&)를 1개 이상 포함해야 합니다"
        }

        return nil
    }
}
