//
//  PaymentDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum PaymentDTOMapper {
    static func toEntity(_ response: PaymentValidationResponse) -> PaymentValidationEntity {
        PaymentValidationEntity(
            paymentId: response.paymentId,
            orderItem: toEntity(response.orderItem),
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: OrderItemResponse) -> OrderItemEntity {
        OrderItemEntity(
            orderId: response.orderId,
            orderCode: response.orderCode,
            totalPrice: response.totalPrice,
            store: OrderDTOMapper.toEntity(response.store),
            orderMenuList: response.orderMenuList.map(OrderDTOMapper.toEntity),
            paidAt: response.paidAt,
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: PaymentReceiptResponse) -> PaymentReceiptEntity {
        PaymentReceiptEntity(
            impUid: response.impUid,
            merchantUid: response.merchantUid,
            payMethod: response.payMethod,
            channel: response.channel,
            pgProvider: response.pgProvider,
            embPgProvider: response.embPgProvider,
            pgTid: response.pgTid,
            pgId: response.pgId,
            escrow: response.escrow,
            applyNum: response.applyNum,
            bankCode: response.bankCode,
            bankName: response.bankName,
            cardCode: response.cardCode,
            cardName: response.cardName,
            cardIssuerCode: response.cardIssuerCode,
            cardIssuerName: response.cardIssuerName,
            cardPublisherCode: response.cardPublisherCode,
            cardPublisherName: response.cardPublisherName,
            cardQuota: response.cardQuota,
            cardNumber: response.cardNumber,
            cardType: response.cardType,
            vbankCode: response.vbankCode,
            vbankName: response.vbankName,
            vbankNum: response.vbankNum,
            vbankHolder: response.vbankHolder,
            vbankDate: response.vbankDate,
            vbankIssuedAt: response.vbankIssuedAt,
            name: response.name,
            amount: response.amount,
            currency: response.currency,
            buyerName: response.buyerName,
            buyerEmail: response.buyerEmail,
            buyerTel: response.buyerTel,
            buyerAddr: response.buyerAddr,
            buyerPostcode: response.buyerPostcode,
            customData: response.customData,
            userAgent: response.userAgent,
            status: response.status,
            startedAt: response.startedAt,
            paidAt: response.paidAt,
            receiptUrl: response.receiptUrl,
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }
}
