//
//  PaymentEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation

// MARK: - 영수증 검증 엔티티
struct PaymentValidationEntity {
    let paymentId: String
    let orderItem: OrderItemEntity
    let createdAt: Date?
    let updatedAt: Date?
}

struct OrderItemEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let store: OrderStoreInfoEntity
    let orderMenuList: [OrderMenuEntity]
    let paidAt: String?
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - 결제 영수증 조회 엔티티
struct PaymentReceiptEntity {
    let impUid: String
    let merchantUid: String
    let payMethod: String
    let channel: String
    let pgProvider: String
    let embPgProvider: String?
    let pgTid: String?
    let pgId: String?
    let escrow: Bool
    let applyNum: String?
    let bankCode: String?
    let bankName: String?
    let cardCode: String?
    let cardName: String?
    let cardIssuerCode: String?
    let cardIssuerName: String?
    let cardPublisherCode: String?
    let cardPublisherName: String?
    let cardQuota: Int
    let cardNumber: String?
    let cardType: Int?
    let vbankCode: String?
    let vbankName: String?
    let vbankNum: String?
    let vbankHolder: String?
    let vbankDate: Int?
    let vbankIssuedAt: Int?
    let name: String
    let amount: Int
    let currency: String
    let buyerName: String
    let buyerEmail: String
    let buyerTel: String
    let buyerAddr: String
    let buyerPostcode: String
    let customData: String?
    let userAgent: String
    let status: String
    let startedAt: String?
    let paidAt: String?
    let receiptUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
}
