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

    init(from response: PaymentValidationResponse) {
        self.paymentId = response.paymentId
        self.orderItem = OrderItemEntity(from: response.orderItem)
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
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

    init(from response: OrderItemResponse) {
        self.orderId = response.orderId
        self.orderCode = response.orderCode
        self.totalPrice = response.totalPrice
        self.store = OrderStoreInfoEntity(from: response.store)
        self.orderMenuList = response.orderMenuList.map { OrderMenuEntity(from: $0) }
        self.paidAt = response.paidAt
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
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

    init(from response: PaymentReceiptResponse) {
        self.impUid = response.impUid
        self.merchantUid = response.merchantUid
        self.payMethod = response.payMethod
        self.channel = response.channel
        self.pgProvider = response.pgProvider
        self.embPgProvider = response.embPgProvider
        self.pgTid = response.pgTid
        self.pgId = response.pgId
        self.escrow = response.escrow
        self.applyNum = response.applyNum
        self.bankCode = response.bankCode
        self.bankName = response.bankName
        self.cardCode = response.cardCode
        self.cardName = response.cardName
        self.cardIssuerCode = response.cardIssuerCode
        self.cardIssuerName = response.cardIssuerName
        self.cardPublisherCode = response.cardPublisherCode
        self.cardPublisherName = response.cardPublisherName
        self.cardQuota = response.cardQuota
        self.cardNumber = response.cardNumber
        self.cardType = response.cardType
        self.vbankCode = response.vbankCode
        self.vbankName = response.vbankName
        self.vbankNum = response.vbankNum
        self.vbankHolder = response.vbankHolder
        self.vbankDate = response.vbankDate
        self.vbankIssuedAt = response.vbankIssuedAt
        self.name = response.name
        self.amount = response.amount
        self.currency = response.currency
        self.buyerName = response.buyerName
        self.buyerEmail = response.buyerEmail
        self.buyerTel = response.buyerTel
        self.buyerAddr = response.buyerAddr
        self.buyerPostcode = response.buyerPostcode
        self.customData = response.customData
        self.userAgent = response.userAgent
        self.status = response.status
        self.startedAt = response.startedAt
        self.paidAt = response.paidAt
        self.receiptUrl = response.receiptUrl
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}
