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
        let loginSuccess: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
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

        let isLoginEnabled = Publishers.CombineLatest(isEmailValid, isPasswordValid)
            .map { emailValid, passwordValid in
                emailValid && passwordValid
            }
            .eraseToAnyPublisher()

        let loginSuccess = input.loginButtonTapped
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                performLogin()
            })
            .eraseToAnyPublisher()

        return Output(
            isEmailValid: isEmailValid,
            isPasswordValid: isPasswordValid,
            emailValidationMessage: emailValidation,
            passwordValidationMessage: passwordValidation,
            isLoginEnabled: isLoginEnabled,
            loginSuccess: loginSuccess
        )
    }

    private func performLogin() {
        TokenManager.shared.saveTokens(
            accessToken: "temp_access_token",
            refreshToken: "temp_refresh_token"
        )
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
