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
    var headerSet: HeaderSet { get }
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

    var headerSet: HeaderSet {
        return .authenticated
    }

    var headers: [String: String]? {
        return headerSet.toHeaders()
    }

    var validationType: ValidationType {
        return .successCodes
    }

    var sampleData: Data {
        return Data()
    }
}
