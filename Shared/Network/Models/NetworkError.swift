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
    case userCancelled

    case serverError(statusCode: Int, message: String)

    case unauthorized
    case accessTokenExpired
    case invalidRefreshToken
    case refreshTokenExpired
    
    case invalidRequest(String)
    case unknown(Error?)

    var errorDescription: String {
        switch self {
        case .noInternetConnection:
            return "네트워크 연결이 불안정합니다. 인터넷 연결을 확인해주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."
        case .decodingFailed(let error):
            return "데이터 처리 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .userCancelled:
            return "사용자가 로그인을 취소했습니다."
        case .serverError(let statusCode, let message):
            return "[\(statusCode)] \(message)"
        case .unauthorized:
            return "인증에 실패했습니다. 로그인 정보를 확인해주세요."
        case .accessTokenExpired:
            return "로그인 세션이 만료되었습니다. 다시 로그인해주세요."
        case .invalidRefreshToken:
            return "인증 정보가 유효하지 않습니다. 다시 로그인해주세요."
        case .refreshTokenExpired:
            return "로그인 세션이 만료되었습니다. 다시 로그인해주세요."
        case .invalidRequest(let message):
            return "유효하지 않은 요청입니다. \(message)"
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
        case .unauthorized:
            return 401
        case .accessTokenExpired:
            return 419
        case .invalidRefreshToken:
            return 401
        case .refreshTokenExpired:
            return 418
        default:
            return nil
        }
    }

    var needsReauthentication: Bool {
        switch self {
        case .accessTokenExpired, .invalidRefreshToken, .refreshTokenExpired:
            return true
        case .serverError(let statusCode, _):
            return statusCode == 419 || statusCode == 401 || statusCode == 418
        default:
            return false
        }
    }

    var isRetryable: Bool {
        switch self {
        case .timeout, .noInternetConnection:
            return true
        case .serverError(let statusCode, _):
            return statusCode == 503 || statusCode >= 500
        case .accessTokenExpired, .invalidRefreshToken, .refreshTokenExpired, .unauthorized, .userCancelled:
            return false
        case .decodingFailed, .unknown, .invalidRequest:
            return false
        }
    }

    var isNetworkConnectionError: Bool {
        switch self {
        case .timeout, .noInternetConnection:
            return true
        default:
            return false
        }
    }
}
