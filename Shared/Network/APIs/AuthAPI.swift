//
//  AuthAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/28/25.
//

import Foundation
import Moya

enum AuthAPI {
    case refreshToken
}

extension AuthAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var headerSet: HeaderSet {
        return .refresh
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
}
