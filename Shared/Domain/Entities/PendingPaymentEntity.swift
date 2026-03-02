//
//  PendingPaymentEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

struct PendingPaymentEntity: Codable {
    let impUID: String
    let orderCode: String
    let amount: Int
    let storeName: String
    let timestamp: Date
    let retryCount: Int

    init(impUID: String, orderCode: String, amount: Int, storeName: String, retryCount: Int = 0) {
        self.impUID = impUID
        self.orderCode = orderCode
        self.amount = amount
        self.storeName = storeName
        self.timestamp = Date()
        self.retryCount = retryCount
    }

    func incrementRetryCount() -> PendingPaymentEntity {
        return PendingPaymentEntity(
            impUID: impUID,
            orderCode: orderCode,
            amount: amount,
            storeName: storeName,
            retryCount: retryCount + 1
        )
    }

    var hasExceededMaxRetries: Bool {
        return retryCount >= 5
    }

    var isExpired: Bool {
        let expirationInterval: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
}
