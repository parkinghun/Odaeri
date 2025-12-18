//
//  BaseAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

protocol BaseAPI: TargetType {
    var apiVersion: String { get }
    var endpoint: String { get }
}

extension BaseAPI {
    var apiVersion: String {
        return APIEnvironment.current.version
    }

    var baseURL: URL {
        return APIEnvironment.current.baseURL
    }

    var path: String {
        return "/\(apiVersion)\(endpoint)"
    }

    var headers: [String: String]? {
        var headers = [String: String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"

        return headers
    }

    var validationType: ValidationType {
        return .successCodes
    }

    var sampleData: Data {
        return Data()
    }
}
