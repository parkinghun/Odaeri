//
//  PaymentAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum PaymentAPI {
    case validateReceipt(impUID: String)
    case fetchReceipt(orderCode: String)
}

extension PaymentAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .validateReceipt:
            return "/payments/validation"
        case let .fetchReceipt(orderCode):
            return "/payments/\(orderCode)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .validateReceipt:
            return .post
        case .fetchReceipt:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .validateReceipt(impUID):
            return .requestParameters(
                parameters: ["imp_uid": impUID],
                encoding: JSONEncoding.default
            )
        case .fetchReceipt:
            return .requestPlain
        }
    }
}
