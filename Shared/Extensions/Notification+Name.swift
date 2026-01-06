//
//  Notification+Name.swift
//  Odaeri
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation

extension Notification.Name {
    static let unauthorizedAccess = Notification.Name("com.odaeri.unauthorizedAccess")
    static let refreshTokenExpired = Notification.Name("com.odaeri.refreshTokenExpired")
    static let pendingPaymentValidated = Notification.Name("com.odaeri.pendingPaymentValidated")
}

struct PendingPaymentValidatedInfo {
    let validationEntity: PaymentValidationEntity
    let storeName: String
    let count: Int
}
