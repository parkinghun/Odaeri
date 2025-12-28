//
//  AuthAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Moya

enum AuthAPI {
    case refreshToken(token: String)
}

extension AuthAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var requiresAuthentication: Bool {
        return true
    }

    var method: Moya.Method {
        switch self {
        case .refreshToken:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .refreshToken:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers = [String: String]()
        headers["Accept"] = "application/json"
        headers["SeSACKey"] = APIEnvironment.current.apiKey
        headers["Authorization"] = TokenManager.shared.accessToken

        
        switch self {
        case .refreshToken(let token):
            headers["RefreshToken"] = token
        }

        return headers
    }
}
