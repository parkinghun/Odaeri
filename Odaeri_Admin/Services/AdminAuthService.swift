//
//  AdminAuthService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya

final class AdminAuthService {
    private let provider: MoyaProvider<UserAPI>

    init(provider: MoyaProvider<UserAPI> = ProviderFactory.makeUserProvider()) {
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
}
