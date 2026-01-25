//
//  UserRepositoryImpl.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import Foundation
import Combine
import Moya
import KakaoSDKCommon
import AuthenticationServices

final class UserRepositoryImpl: UserRepository {
    private let provider: MoyaProvider<UserAPI>
    private let kakaoService: KakaoLoginServiceProtocol
    private let appleService: AppleLoginServiceProtocol

    init(
        kakaoService: KakaoLoginServiceProtocol = DefaultKakaoLoginService(),
        appleService: AppleLoginServiceProtocol = DefaultAppleLoginService(),
        provider: MoyaProvider<UserAPI> = MoyaProvider<UserAPI>(plugins: [NetworkLoggerPlugin()])
    ) {
        self.kakaoService = kakaoService
        self.appleService = appleService
        self.provider = provider
    }

    func emailLogin(email: String, password: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        let request = EmailLoginRequest(
            email: email,
            password: password,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(UserAPI.emailLogin(request: request))
            .map { (response: UserResponse) in
                UserResult(from: response)
            }
            .eraseToAnyPublisher()
    }

    func kakaoLogin(deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        kakaoService.login()
            .mapError { [weak self] error in
                self?.mapKakaoLoginError(error) ?? .unknown(error)
            }
            .flatMap { [weak self] oauthToken -> AnyPublisher<UserResult, NetworkError> in
                guard let self else {
                    return Fail(
                        error: NetworkError.unknown(
                            NSError(domain: "UserRepositoryImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])
                        )
                    )
                    .eraseToAnyPublisher()
                }

                let request = KakaoLoginRequest(
                    oauthToken: oauthToken.accessToken,
                    deviceToken: deviceToken
                )

                return self.provider.requestPublisher(UserAPI.kakaoLogin(request: request))
                    .map { (response: UserResponse) in
                        UserResult(from: response)
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { userResult in
                TokenManager.shared.saveTokens(
                    accessToken: userResult.accessToken,
                    refreshToken: userResult.refreshToken
                )

                let user = UserEntity(from: userResult)
                UserManager.shared.saveUser(user)
            })
            .eraseToAnyPublisher()
    }

    func appleLogin(deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        print("[AppleLogin] Starting Apple Login")
        print("[AppleLogin] deviceToken length: \(deviceToken.count)")

        return appleService.login()
            .handleEvents(
                receiveOutput: { idToken in
                    print("[AppleLogin] Received idToken from AppleService")
                    print("[AppleLogin] idToken length: \(idToken.count)")
                    print("[AppleLogin] idToken preview: \(String(idToken.prefix(50)))...")
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[AppleLogin] AppleService login failed: \(error)")
                    }
                }
            )
            .mapError { [weak self] error in
                print("[AppleLogin] Mapping Apple login error: \(error)")
                return self?.mapAppleLoginError(error) ?? .unknown(error)
            }
            .flatMap { [weak self] idToken -> AnyPublisher<UserResult, NetworkError> in
                guard let self else {
                    print("[AppleLogin] ERROR: Repository deallocated")
                    return Fail(
                        error: NetworkError.unknown(
                            NSError(domain: "UserRepositoryImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])
                        )
                    )
                    .eraseToAnyPublisher()
                }

                let request = AppleLoginRequest(
                    idToken: idToken,
                    deviceToken: deviceToken
                )

                print("[AppleLogin] Sending request to server")
                print("[AppleLogin] Request - idToken: \(String(idToken.prefix(50)))...")
                print("[AppleLogin] Request - deviceToken: \(String(deviceToken.prefix(30)))...")

                return self.provider.requestPublisher(UserAPI.appleLogin(request: request))
                    .handleEvents(
                        receiveOutput: { response in
                            print("[AppleLogin] Server response received successfully")
                            print("[AppleLogin] Response user_id: \(response.userId)")
                            print("[AppleLogin] Response email: \(response.email)")
                        },
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("[AppleLogin] Server request failed: \(error)")
                                if let networkError = error as? NetworkError {
                                    print("[AppleLogin] NetworkError: \(networkError.errorDescription)")
                                    if case .serverError(let statusCode, let message) = networkError {
                                        print("[AppleLogin] Status Code: \(statusCode)")
                                        print("[AppleLogin] Error Message: \(message)")
                                    }
                                }
                            }
                        }
                    )
                    .map { (response: UserResponse) in
                        print("[AppleLogin] Mapping UserResponse to UserResult")
                        return UserResult(from: response)
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(
                receiveOutput: { userResult in
                    print("[AppleLogin] Login successful, saving tokens")
                    TokenManager.shared.saveTokens(
                        accessToken: userResult.accessToken,
                        refreshToken: userResult.refreshToken
                    )

                    let user = UserEntity(from: userResult)
                    UserManager.shared.saveUser(user)
                    print("[AppleLogin] User saved: \(user.email)")
                }
            )
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, NetworkError> {
        return provider.requestPublisher(UserAPI.logout)
    }

    func getMyProfile() -> AnyPublisher<UserEntity, NetworkError> {
        provider.requestPublisher(UserAPI.getMyProfile)
            .map { (response: ProfileResponse) in
                UserEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func searchUsers(nick: String) -> AnyPublisher<[UserSearchResult], NetworkError> {
        return provider.requestPublisher(UserAPI.searchUsers(nick: nick))
            .map { (response: UserSearchResponse) in
                response.data.map { UserSearchResult(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func validateEmail(email: String) -> AnyPublisher<Void, NetworkError> {
        let request = EmailValidationRequest(email: email)
        return provider.requestPublisher(UserAPI.validateEmail(request: request))
    }

    func join(email: String, password: String, nick: String, phoneNum: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        let request = JoinRequest(
            email: email,
            password: password,
            nick: nick,
            phoneNum: phoneNum,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(UserAPI.join(request: request))
            .map { (response: UserResponse) in
                UserResult(from: response)
            }
            .eraseToAnyPublisher()
    }
}

private extension UserRepositoryImpl {
    func mapKakaoLoginError(_ error: Error) -> NetworkError {
        if let sdkError = error as? SdkError, sdkError.isClientFailed {
            let clientError = sdkError.getClientError()
            if clientError.reason == .Cancelled {
                return .userCancelled
            }
        }

        return .unknown(error)
    }

    func mapAppleLoginError(_ error: Error) -> NetworkError {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            return .userCancelled
        }

        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            return .userCancelled
        }

        return .unknown(error)
    }
}
