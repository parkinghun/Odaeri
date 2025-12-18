//
//  PaymentAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum PaymentAPI {
    case createPayment(orderId: Int, paymentMethod: String, amount: Int)
    case getPaymentDetail(paymentId: Int)
    case getPaymentHistory(page: Int, limit: Int)
    case requestRefund(paymentId: Int, reason: String)
}

extension PaymentAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createPayment:
            return "/payments"
        case .getPaymentDetail(let paymentId):
            return "/payments/\(paymentId)"
        case .getPaymentHistory:
            return "/payments/history"
        case .requestRefund(let paymentId, _):
            return "/payments/\(paymentId)/refund"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createPayment, .requestRefund:
            return .post
        case .getPaymentDetail, .getPaymentHistory:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .createPayment(orderId, paymentMethod, amount):
            return .requestParameters(
                parameters: [
                    "orderId": orderId,
                    "paymentMethod": paymentMethod,
                    "amount": amount
                ],
                encoding: JSONEncoding.default
            )

        case .getPaymentDetail:
            return .requestPlain

        case let .getPaymentHistory(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .requestRefund(_, reason):
            return .requestParameters(
                parameters: ["reason": reason],
                encoding: JSONEncoding.default
            )
        }
    }
}
