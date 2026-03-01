//
//  AuthDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum AuthDTOMapper {
    static func toEntity(_ response: RefreshTokenResponse) -> RefreshTokenEntity {
        RefreshTokenEntity(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }
}
