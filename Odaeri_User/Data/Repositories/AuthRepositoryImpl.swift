//
//  AuthRepositoryImpl.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import Foundation
import Combine
import Moya

final class AuthRepositoryImpl: AuthRepository {
    private let provider: MoyaProvider<AuthAPI>

    init(provider: MoyaProvider<AuthAPI> = MoyaProvider<AuthAPI>()) {
        self.provider = provider
    }

    func emailLogin(email: String, password: String, deviceToken: String) -> AnyPublisher<AuthResult, NetworkError> {
        let request = EmailLoginRequest(
            email: email,
            password: password,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(AuthAPI.emailLogin(request: request))
            .map { (response: AuthResponse) in
                AuthResult(from: response)
            }
            .eraseToAnyPublisher()
    }

    func kakaoLogin(oauthToken: String, deviceToken: String) -> AnyPublisher<AuthResult, NetworkError> {
        let request = KakaoLoginRequest(
            oauthToken: oauthToken,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(AuthAPI.kakaoLogin(request: request))
            .map { (response: AuthResponse) in
                AuthResult(from: response)
            }
            .eraseToAnyPublisher()
    }

    func appleLogin(idToken: String, deviceToken: String) -> AnyPublisher<AuthResult, NetworkError> {
        let request = AppleLoginRequest(
            idToken: idToken,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(AuthAPI.appleLogin(request: request))
            .map { (response: AuthResponse) in
                AuthResult(from: response)
            }
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, NetworkError> {
        return provider.requestPublisher(AuthAPI.logout)
    }

    func validateEmail(email: String) -> AnyPublisher<Void, NetworkError> {
        let request = EmailValidationRequest(email: email)
        return provider.requestPublisher(AuthAPI.validateEmail(request: request))
    }

    func join(email: String, password: String, nick: String, phoneNum: String, deviceToken: String) -> AnyPublisher<AuthResult, NetworkError> {
        let request = JoinRequest(
            email: email,
            password: password,
            nick: nick,
            phoneNum: phoneNum,
            deviceToken: deviceToken
        )

        return provider.requestPublisher(AuthAPI.join(request: request))
            .map { (response: AuthResponse) in
                AuthResult(from: response)
            }
            .eraseToAnyPublisher()
    }
}
