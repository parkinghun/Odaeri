//
//  OrderEntity.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

enum OrderStatusEntity: String, Codable, CaseIterable, Hashable {
    case pendingApproval = "PENDING_APPROVAL"
    case approved = "APPROVED"
    case inProgress = "IN_PROGRESS"
    case readyForPickup = "READY_FOR_PICKUP"
    case pickedUp = "PICKED_UP"

    var description: String {
        switch self {
        case .pendingApproval: return "승인 대기"
        case .approved: return "주문 승인"
        case .inProgress: return "조리 중"
        case .readyForPickup: return "픽업 대기"
        case .pickedUp: return "픽업 완료"
        }
    }

    var stepNumber: Int {
        switch self {
        case .pendingApproval: return 1
        case .approved: return 2
        case .inProgress: return 3
        case .readyForPickup: return 4
        case .pickedUp: return 5
        }
    }

    var iconName: String {
        switch self {
        case .pendingApproval: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .inProgress: return "flame.fill"
        case .readyForPickup: return "bell.fill"
        case .pickedUp: return "checkmark.seal.fill"
        }
    }
}

struct OrderCreateEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: Date?
    let updatedAt: Date?
}

struct OrderListItemEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: OrderReviewEntity?
    let store: OrderStoreInfoEntity
    let orderMenuList: [OrderMenuEntity]
    let currentOrderStatus: OrderStatusEntity
    let orderStatusTimeline: [OrderStatusTimelineEntity]
    let paidAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

struct OrderReviewEntity {
    let id: String
    let rating: Int
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
}

struct OrderMenuEntity {
    let menu: OrderMenuDetailEntity
    let quantity: Int
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
}

struct OrderStatusTimelineEntity {
    let status: OrderStatusEntity
    let completed: Bool
    let changedAt: Date?
}
