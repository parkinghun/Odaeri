//
//  AuthRepositoryImpl.swift
//  Odaeri
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Combine
import Moya

final class AuthRepositoryImpl: AuthRepository {
    private let provider: MoyaProvider<AuthAPI>

    init(provider: MoyaProvider<AuthAPI> = MoyaProvider<AuthAPI>(plugins: [NetworkLoggerPlugin()])) {
        self.provider = provider
    }

    func refreshToken() -> AnyPublisher<RefreshTokenEntity, NetworkError> {
        return provider.requestPublisher(AuthAPI.refreshToken)
            .map { (response: RefreshTokenResponse) in
                AuthDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
    }
}
