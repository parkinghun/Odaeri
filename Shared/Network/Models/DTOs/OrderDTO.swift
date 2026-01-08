//
//  OrderDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

//MARK: - Request
struct OrderCreateRequest: Encodable {
    let storeId: String
    let orderMenuList: [OrderMenuItem]
    let totalPrice: Int

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case orderMenuList = "order_menu_list"
        case totalPrice = "total_price"
    }
}

struct OrderMenuItem: Encodable {
    let menuId: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case quantity
    }
}

struct OrderStatusUpdateRequest: Encodable {
    let nextStatus: String
    
    init(status: OrderStatusEntity) {
        self.nextStatus = status.rawValue
    }
}

//MARK: - Response
struct OrderCreateResponse: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt, updatedAt
    }
}

struct OrderListResponse: Decodable {
    let data: [OrderListItem]
}

struct OrderListItem: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: OrderReviewItem?
    let store: OrderStoreInfo
    let orderMenuList: [OrderMenuDTO]
    let currentOrderStatus: String
    let orderStatusTimeline: [OrderStatusTimelineDTO]
    let paidAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case review, store
        case orderMenuList = "order_menu_list"
        case currentOrderStatus = "current_order_status"
        case orderStatusTimeline = "order_status_timeline"
        case paidAt, createdAt, updatedAt
    }
}

struct OrderReviewItem: Decodable {
    let id: String
    let rating: Int
}

struct OrderStoreInfo: Decodable {
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

struct OrderMenuDTO: Decodable {
    let menu: OrderMenuDetail
    let quantity: Int
}

struct OrderMenuDetail: Decodable {
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

struct OrderStatusTimelineDTO: Decodable {
    let status: String
    let completed: Bool
    let changedAt: String?
}
