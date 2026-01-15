//
//  UserRepositoryImpl.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import Foundation
import Combine
import Moya

final class UserRepositoryImpl: UserRepository {
    private let provider: MoyaProvider<UserAPI>

    init(provider: MoyaProvider<UserAPI> = MoyaProvider<UserAPI>(plugins: [NetworkLoggerPlugin()])) {
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

    func kakaoLogin(oauthToken: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        let request = KakaoLoginRequest(
            oauthToken: oauthToken,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(UserAPI.kakaoLogin(request: request))
            .map { (response: UserResponse) in
                UserResult(from: response)
            }
            .eraseToAnyPublisher()
    }

    func appleLogin(idToken: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError> {
        let request = AppleLoginRequest(
            idToken: idToken,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(UserAPI.appleLogin(request: request))
            .map { (response: UserResponse) in
                UserResult(from: response)
            }
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
