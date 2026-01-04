//
//  BannerRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import Foundation
import Combine
import Moya

final class BannerRepositoryImpl: BannerRepository {
    private let provider = MoyaProvider<BannerAPI>()
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager = TokenManager.shared) {
        self.tokenManager = tokenManager
    }

    func fetchBanners() -> AnyPublisher<[BannerEntity], NetworkError> {
        provider.requestPublisher(.getBanners)
            .map { (response: BannerResponse) in
                response.data.map { BannerEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func getAccessToken() -> String? {
        return tokenManager.accessToken
    }
}
