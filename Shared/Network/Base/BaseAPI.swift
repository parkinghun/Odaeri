//
//  BaseAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

protocol BaseAPI: TargetType {
    // 각 API에서 구현해야 할 것들
}

extension BaseAPI {
    var baseURL: URL {
        return APIEnvironment.current.baseURL
    }

    var headers: [String: String]? {
        var headers = [String: String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"

        // 필요시 각 API에서 오버라이드하여 토큰 추가 가능
        // AuthPlugin으로 처리할 수도 있음
        return headers
    }

    var validationType: ValidationType {
        return .successCodes
    }

    var sampleData: Data {
        return Data()
    }
}
