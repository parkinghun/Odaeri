//
//  AuthDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

// MARK: - Request Models

struct EmailValidationRequest: Encodable {
    let email: String
}

struct JoinRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String
    let deviceToken: String
}

struct EmailLoginRequest: Encodable {
    let email: String
    let password: String
    let deviceToken: String
}

struct KakaoLoginRequest: Encodable {
    let oauthToken: String
    let deviceToken: String
}

struct AppleLoginRequest: Encodable {
    let idToken: String
    let deviceToken: String
}

struct DeviceTokenRequest: Encodable {
    let deviceToken: String
}

struct ProfileUpdateRequest: Encodable {
    let nick: String?
    let phoneNum: String?
    let profileImage: String?
}

// MARK: - Response Models

struct MessageResponse: Decodable {
    let message: String
}

struct AuthResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick
        case profileImage
        case accessToken, refreshToken
    }
}

struct ProfileResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String
    let phoneNum: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick
        case profileImage
        case phoneNum
    }
}

struct ProfileImageUploadResponse: Decodable {
    let profileImage: String
}

struct UserSearchResponse: Decodable {
    let data: [UserSearchItem]
}

struct UserSearchItem: Decodable {
    let userId: String
    let nick: String
    let profileImage: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}
