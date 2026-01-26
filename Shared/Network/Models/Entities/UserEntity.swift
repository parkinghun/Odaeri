//
//  UserEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

struct UserEntity {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?

    init(
        userId: String,
        email: String,
        nick: String,
        profileImage: String,
        phoneNum: String?
    ) {
        self.userId = userId
        self.email = email
        self.nick = nick
        self.profileImage = profileImage
        self.phoneNum = phoneNum
    }

    init(from response: ProfileResponse) {
        self.userId = response.userId
        self.email = response.email
        self.nick = response.nick
        self.profileImage = response.profileImage
        self.phoneNum = response.phoneNum
    }

    init(from userResult: UserResult) {
        self.userId = userResult.userId
        self.email = userResult.email
        self.nick = userResult.nick
        self.profileImage = userResult.profileImage ?? ""
        self.phoneNum = nil
    }
}

struct UserResult {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String

    init(
        userId: String,
        email: String,
        nick: String,
        profileImage: String?,
        accessToken: String,
        refreshToken: String
    ) {
        self.userId = userId
        self.email = email
        self.nick = nick
        self.profileImage = profileImage
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    init(from response: UserResponse) {
        self.userId = response.userId
        self.email = response.email
        self.nick = response.nick
        self.profileImage = response.profileImage
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
    }
}

struct UserSearchResult {
    let userId: String
    let nick: String
    let profileImage: String

    init(
        userId: String,
        nick: String,
        profileImage: String
    ) {
        self.userId = userId
        self.nick = nick
        self.profileImage = profileImage
    }

    init(from item: UserSearchItem) {
        self.userId = item.userId
        self.nick = item.nick
        self.profileImage = item.profileImage
    }
}
