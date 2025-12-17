//
//  NetworkError.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum NetworkError: Error {
    case noInternetConnection
    case timeout
    case decodingFailed(Error)

    case serverError(statusCode: Int, message: String)

    case accessTokenExpired

    case unknown(Error?)

    var errorDescription: String {
        switch self {
        case .noInternetConnection:
            return "네트워크 연결이 불안정합니다. 인터넷 연결을 확인해주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."
        case .decodingFailed(let error):
            return "데이터 처리 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "[\(statusCode)] \(message)"
        case .accessTokenExpired:
            return "로그인 세션이 만료되었습니다. 다시 로그인해주세요."
        case .unknown(let error):
            if let error = error {
                return "알 수 없는 오류: \(error.localizedDescription)"
            }
            return "알 수 없는 오류가 발생했습니다."
        }
    }

    var statusCode: Int? {
        switch self {
        case .serverError(let code, _):
            return code
        case .accessTokenExpired:
            return 419
        default:
            return nil
        }
    }

    var needsReauthentication: Bool {
        switch self {
        case .accessTokenExpired:
            return true
        case .serverError(let statusCode, _):
            return statusCode == 419
        default:
            return false
        }
    }
}
