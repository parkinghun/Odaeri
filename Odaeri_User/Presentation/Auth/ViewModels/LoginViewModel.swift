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
        let kakaoLoginTapped: AnyPublisher<Void, Never>
        let appleLoginTapped: AnyPublisher<Void, Never>
        let signUpTapped: AnyPublisher<Void, Never>
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
            .map { email in
                InputValidator.validateEmail(email)
            }
            .eraseToAnyPublisher()

        let isPasswordValid = input.passwordText
            .map { password in
                InputValidator.validatePassword(password)
            }
            .eraseToAnyPublisher()

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

        input.kakaoLoginTapped
            .sink { [weak self] _ in
                self?.performKakaoLogin(completion: {
                    self?.coordinator?.didFinishLogin()
                })
            }
            .store(in: &cancellables)

        input.appleLoginTapped
            .sink { [weak self] _ in
                self?.performAppleLogin(completion: {
                    self?.coordinator?.didFinishLogin()
                })
            }
            .store(in: &cancellables)

        input.signUpTapped
            .sink { [weak self] _ in
                self?.coordinator?.showSignUp()
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

    private func performKakaoLogin(completion: @escaping () -> Void) {
        guard let deviceToken = TokenManager.shared.deviceToken else {
            loginErrorSubject.send("디바이스 토큰이 없습니다. 앱을 재시작해주세요.")
            return
        }

        isLoadingSubject.send(true)

        repository.kakaoLogin(deviceToken: deviceToken)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoadingSubject.send(false)

                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        if case .userCancelled = error {
                            break
                        }
                        self?.loginErrorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { _ in
                    completion()
                }
            )
            .store(in: &cancellables)
    }

    private func performAppleLogin(completion: @escaping () -> Void) {
        print("[LoginViewModel] performAppleLogin called")

        guard let deviceToken = TokenManager.shared.deviceToken else {
            print("[LoginViewModel] ERROR: deviceToken is nil")
            loginErrorSubject.send("디바이스 토큰이 없습니다. 앱을 재시작해주세요.")
            return
        }

        print("[LoginViewModel] deviceToken exists, length: \(deviceToken.count)")
        isLoadingSubject.send(true)

        repository.appleLogin(deviceToken: deviceToken)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoadingSubject.send(false)

                    switch result {
                    case .finished:
                        print("[LoginViewModel] Apple login completed successfully")
                    case .failure(let error):
                        print("[LoginViewModel] Apple login failed with error: \(error)")
                        print("[LoginViewModel] Error description: \(error.errorDescription)")

                        if case .userCancelled = error {
                            print("[LoginViewModel] User cancelled login")
                            break
                        }
                        self?.loginErrorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { userResult in
                    print("[LoginViewModel] Received userResult: \(userResult.email)")
                    completion()
                }
            )
            .store(in: &cancellables)
    }
}
