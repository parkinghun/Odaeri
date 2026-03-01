//
//  UserDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum UserDTOMapper {
    static func toResult(_ response: UserResponse) -> UserResult {
        UserResult(
            userId: response.userId,
            email: response.email,
            nick: response.nick,
            profileImage: response.profileImage,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    static func toEntity(_ response: ProfileResponse) -> UserEntity {
        UserEntity(
            userId: response.userId,
            email: response.email,
            nick: response.nick,
            profileImage: response.profileImage ?? "",
            phoneNum: response.phoneNum
        )
    }

    static func toEntity(_ userResult: UserResult) -> UserEntity {
        UserEntity(
            userId: userResult.userId,
            email: userResult.email,
            nick: userResult.nick,
            profileImage: userResult.profileImage ?? "",
            phoneNum: nil
        )
    }

    static func toEntity(_ item: UserSearchItem) -> UserSearchResult {
        UserSearchResult(
            userId: item.userId,
            nick: item.nick,
            profileImage: item.profileImage
        )
    }
}
