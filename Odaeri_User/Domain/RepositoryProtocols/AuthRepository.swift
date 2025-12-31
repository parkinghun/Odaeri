//
//  AuthRepository.swift
//  Odaeri
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Combine

protocol AuthRepository {
    func refreshToken() -> AnyPublisher<RefreshTokenResponse, NetworkError>
}
