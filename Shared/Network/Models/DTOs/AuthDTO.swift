//
//  AuthDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
