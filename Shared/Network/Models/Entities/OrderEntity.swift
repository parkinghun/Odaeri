//
//  OrderEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

enum OrderStatusEntity: String, Codable, CaseIterable {
    case pendingApproval = "PENDING_APPROVAL"
    case approved = "APPROVED"
    case inProgress = "IN_PROGRESS"
    case readyForPickup = "READY_FOR_PICKUP"
    case pickedUp = "PICKED_UP"
    
    // UI 표시용 텍스트 (필요 시)
    var description: String {
        switch self {
        case .pendingApproval: return "승인 대기"
        case .approved: return "주문 승인"
        case .inProgress: return "조리 중"
        case .readyForPickup: return "픽업 대기"
        case .pickedUp: return "픽업 완료"
        }
    }
}

struct OrderCreateEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: Date?
    let updatedAt: Date?

    init(from response: OrderCreateResponse) {
        self.orderId = response.orderId
        self.orderCode = response.orderCode
        self.totalPrice = response.totalPrice
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}

struct OrderListItemEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: OrderReviewEntity
    let store: OrderStoreInfoEntity
    let orderMenuList: [OrderMenuEntity]
    let currentOrderStatus: OrderStatusEntity
    let orderStatusTimeline: [OrderStatusTimelineEntity]
    let paidAt: String?
    let createdAt: Date?
    let updatedAt: Date?

    init(from response: OrderListItem) {
        self.orderId = response.orderId
        self.orderCode = response.orderCode
        self.totalPrice = response.totalPrice
        self.review = OrderReviewEntity(from: response.review)
        self.store = OrderStoreInfoEntity(from: response.store)
        self.orderMenuList = response.orderMenuList.map { OrderMenuEntity(from: $0) }
        self.currentOrderStatus = OrderStatusEntity(rawValue: response.currentOrderStatus) ?? .pendingApproval
        self.orderStatusTimeline = response.orderStatusTimeline.map { OrderStatusTimelineEntity(from: $0) }
        self.paidAt = response.paidAt
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}

struct OrderReviewEntity {
    let id: String
    let rating: Int

    init(from response: OrderReviewItem) {
        self.id = response.id
        self.rating = response.rating
    }
}

struct OrderStoreInfoEntity {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let longitude: Double
    let latitude: Double
    let createdAt: Date?
    let updatedAt: Date?

    init(from response: OrderStoreInfo) {
        self.id = response.id
        self.category = response.category
        self.name = response.name
        self.close = response.close
        self.storeImageUrls = response.storeImageUrls
        self.hashTags = response.hashTags
        self.longitude = response.geolocation.longitude
        self.latitude = response.geolocation.latitude
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}

struct OrderMenuEntity {
    let menu: OrderMenuDetailEntity
    let quantity: Int

    init(from response: OrderMenuDTO) {
        self.menu = OrderMenuDetailEntity(from: response.menu)
        self.quantity = response.quantity
    }
}

struct OrderMenuDetailEntity {
    let id: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let tags: [String]
    let menuImageUrl: String
    let createdAt: Date?
    let updatedAt: Date?

    init(from response: OrderMenuDetail) {
        self.id = response.id
        self.category = response.category
        self.name = response.name
        self.description = response.description
        self.originInformation = response.originInformation
        self.price = response.price
        self.tags = response.tags
        self.menuImageUrl = response.menuImageUrl
        self.createdAt = response.createdAt.toDate()
        self.updatedAt = response.updatedAt.toDate()
    }
}

struct OrderStatusTimelineEntity {
    let status: OrderStatusEntity
    let completed: Bool
    let changedAt: Date?

    init(from response: OrderStatusTimelineDTO) {
        self.status = OrderStatusEntity(rawValue: response.status) ?? .pendingApproval
        self.completed = response.completed
        self.changedAt = response.changedAt.toDate()
    }
}
