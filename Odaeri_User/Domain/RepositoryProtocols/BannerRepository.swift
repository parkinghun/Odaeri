//
//  BannerRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import Foundation
import Combine

protocol BannerRepository {
    /// 배너 목록 조회
    func fetchBanners() -> AnyPublisher<[BannerEntity], NetworkError>

    /// 웹뷰 이벤트용 액세스 토큰 조회
    func getAccessToken() -> String?
}
