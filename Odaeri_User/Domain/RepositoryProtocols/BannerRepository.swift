//
//  BannerRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import Foundation
import Combine

protocol BannerRepository {
    func fetchBanners() -> AnyPublisher<[BannerEntity], NetworkError>
}
