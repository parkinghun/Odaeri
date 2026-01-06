//
//  PaymentDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation

// MARK: - 영수증 검증 요청
struct PaymentValidationRequest: Encodable {
    let impUid: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
    }
}

// MARK: - 영수증 검증 응답
struct PaymentValidationResponse: Decodable {
    let paymentId: String
    let orderItem: OrderItemResponse
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt, updatedAt
    }
}

struct OrderItemResponse: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let store: StoreInfoResponse
    let orderMenuList: [OrderMenuResponse]
    let paidAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case store
        case orderMenuList = "order_menu_list"
        case paidAt, createdAt, updatedAt
    }
}

struct StoreInfoResponse: Decodable {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let geolocation: Geolocation
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, category, name, close
        case storeImageUrls = "store_image_urls"
        case hashTags, geolocation, createdAt, updatedAt
    }
}

struct OrderMenuResponse: Decodable {
    let menu: MenuDetailResponse
    let quantity: Int
}

struct MenuDetailResponse: Decodable {
    let id: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let tags: [String]
    let menuImageUrl: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, category, name, description
        case originInformation = "origin_information"
        case price, tags
        case menuImageUrl = "menu_image_url"
        case createdAt, updatedAt
    }
}

// MARK: - 결제 영수증 조회 응답
struct PaymentReceiptResponse: Decodable {
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
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
        case merchantUid = "merchant_uid"
        case payMethod = "pay_method"
        case channel
        case pgProvider = "pg_provider"
        case embPgProvider = "emb_pg_provider"
        case pgTid = "pg_tid"
        case pgId = "pg_id"
        case escrow
        case applyNum = "apply_num"
        case bankCode = "bank_code"
        case bankName = "bank_name"
        case cardCode = "card_code"
        case cardName = "card_name"
        case cardIssuerCode = "card_issuer_code"
        case cardIssuerName = "card_issuer_name"
        case cardPublisherCode = "card_publisher_code"
        case cardPublisherName = "card_publisher_name"
        case cardQuota = "card_quota"
        case cardNumber = "card_number"
        case cardType = "card_type"
        case vbankCode = "vbank_code"
        case vbankName = "vbank_name"
        case vbankNum = "vbank_num"
        case vbankHolder = "vbank_holder"
        case vbankDate = "vbank_date"
        case vbankIssuedAt = "vbank_issued_at"
        case name, amount, currency
        case buyerName = "buyer_name"
        case buyerEmail = "buyer_email"
        case buyerTel = "buyer_tel"
        case buyerAddr = "buyer_addr"
        case buyerPostcode = "buyer_postcode"
        case customData = "custom_data"
        case userAgent = "user_agent"
        case status
        case startedAt, paidAt
        case receiptUrl = "receipt_url"
        case createdAt, updatedAt
    }
}
