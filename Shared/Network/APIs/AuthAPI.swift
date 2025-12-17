//
//  AuthAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum AuthAPI {
    case login(email: String, password: String)
    case signup(email: String, password: String, nickname: String)
    case refreshToken(refreshToken: String)
    case logout
    case withdraw
    case verifyEmail(email: String)
    case checkEmailDuplicate(email: String)
}

extension AuthAPI: BaseAPI {
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
        case .withdraw:
            return "/auth/withdraw"
        case .verifyEmail:
            return "/auth/verify-email"
        case .checkEmailDuplicate:
            return "/auth/check-email"
        }
    }

    var method: Moya.Method {
        switch self {
        case .login, .signup, .refreshToken, .logout, .verifyEmail:
            return .post
        case .withdraw:
            return .delete
        case .checkEmailDuplicate:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .login(email, password):
            return .requestParameters(
                parameters: ["email": email, "password": password],
                encoding: JSONEncoding.default
            )

        case let .signup(email, password, nickname):
            return .requestParameters(
                parameters: [
                    "email": email,
                    "password": password,
                    "nickname": nickname
                ],
                encoding: JSONEncoding.default
            )

        case let .refreshToken(token):
            return .requestParameters(
                parameters: ["refreshToken": token],
                encoding: JSONEncoding.default
            )

        case .logout, .withdraw:
            return .requestPlain

        case let .verifyEmail(email):
            return .requestParameters(
                parameters: ["email": email],
                encoding: JSONEncoding.default
            )

        case let .checkEmailDuplicate(email):
            return .requestParameters(
                parameters: ["email": email],
                encoding: URLEncoding.queryString
            )
        }
    }
}
