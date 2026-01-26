//
//  SignUpViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation
import Combine

final class SignUpViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: AuthCoordinator?

    private let repository: UserRepository
    private let currentEmail = CurrentValueSubject<String, Never>("")
    private let currentPassword = CurrentValueSubject<String, Never>("")
    private let currentNick = CurrentValueSubject<String, Never>("")
    private let currentPhone = CurrentValueSubject<String, Never>("")
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let signUpErrorSubject = PassthroughSubject<String, Never>()

    init(repository: UserRepository = UserRepositoryImpl()) {
        self.repository = repository
    }

    struct Input {
        let emailText: AnyPublisher<String, Never>
        let passwordText: AnyPublisher<String, Never>
        let nickText: AnyPublisher<String, Never>
        let phoneText: AnyPublisher<String, Never>
        let signUpTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let emailValidationMessage: AnyPublisher<String, Never>
        let passwordValidationMessage: AnyPublisher<String, Never>
        let nickValidationMessage: AnyPublisher<String, Never>
        let isSignUpEnabled: AnyPublisher<Bool, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let signUpError: AnyPublisher<String, Never>
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

        input.nickText
            .sink { [weak self] nick in
                self?.currentNick.send(nick)
            }
            .store(in: &cancellables)

        input.phoneText
            .sink { [weak self] phone in
                self?.currentPhone.send(phone)
            }
            .store(in: &cancellables)

        let emailValidation = input.emailText
            .map { InputValidator.emailValidationMessage(for: $0) ?? "" }
            .eraseToAnyPublisher()

        let passwordValidation = input.passwordText
            .map { InputValidator.passwordValidationMessage(for: $0) ?? "" }
            .eraseToAnyPublisher()

        let nickValidation = input.nickText
            .map { InputValidator.nicknameValidationMessage(for: $0) ?? "" }
            .eraseToAnyPublisher()

        let isSignUpEnabled = Publishers.CombineLatest4(
            input.emailText.map { InputValidator.validateEmail($0) },
            input.passwordText.map { InputValidator.validatePassword($0) },
            input.nickText.map { InputValidator.validateNickname($0) },
            isLoadingSubject
        )
        .map { emailValid, passwordValid, nickValid, isLoading in
            emailValid && passwordValid && nickValid && !isLoading
        }
        .eraseToAnyPublisher()

        input.signUpTapped
            .sink { [weak self] _ in
                self?.performSignUp()
            }
            .store(in: &cancellables)

        return Output(
            emailValidationMessage: emailValidation,
            passwordValidationMessage: passwordValidation,
            nickValidationMessage: nickValidation,
            isSignUpEnabled: isSignUpEnabled,
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            signUpError: signUpErrorSubject.eraseToAnyPublisher()
        )
    }
}

private extension SignUpViewModel {
    func performSignUp() {
        let email = currentEmail.value
        let password = currentPassword.value
        let nick = currentNick.value
        let phone = currentPhone.value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let deviceToken = TokenManager.shared.deviceToken else {
            signUpErrorSubject.send("디바이스 토큰이 없습니다. 앱을 재시작해주세요.")
            return
        }

        isLoadingSubject.send(true)

        repository.join(
            email: email,
            password: password,
            nick: nick,
            phoneNum: phone.isEmpty ? "" : phone,
            deviceToken: deviceToken
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingSubject.send(false)

                if case .failure(let error) = completion {
                    self?.signUpErrorSubject.send(self?.mapSignUpError(error) ?? error.errorDescription)
                }
            },
            receiveValue: { [weak self] userResult in
                TokenManager.shared.saveTokens(
                    accessToken: userResult.accessToken,
                    refreshToken: userResult.refreshToken
                )

                let user = UserEntity(from: userResult)
                UserManager.shared.saveUser(user)

                self?.coordinator?.didFinishLogin()
            }
        )
        .store(in: &cancellables)
    }

    func mapSignUpError(_ error: NetworkError) -> String {
        if case let .serverError(statusCode, message) = error, statusCode == 409 {
            return message.isEmpty ? "이미 가입된 유저입니다." : message
        }
        return error.errorDescription
    }
}
