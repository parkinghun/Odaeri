//
//  OrderDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum OrderDTOMapper {
    static func toEntity(_ response: OrderCreateResponse) -> OrderCreateEntity {
        OrderCreateEntity(
            orderId: response.orderId,
            orderCode: response.orderCode,
            totalPrice: response.totalPrice,
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: OrderListItem) -> OrderListItemEntity {
        OrderListItemEntity(
            orderId: response.orderId,
            orderCode: response.orderCode,
            totalPrice: response.totalPrice,
            review: toEntity(response.review),
            store: toEntity(response.store),
            orderMenuList: response.orderMenuList.map(toEntity),
            currentOrderStatus: OrderStatusEntity(rawValue: response.currentOrderStatus) ?? .pendingApproval,
            orderStatusTimeline: response.orderStatusTimeline.map(toEntity),
            paidAt: response.paidAt?.toDate(),
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: OrderStoreInfo) -> OrderStoreInfoEntity {
        OrderStoreInfoEntity(
            id: response.id,
            category: response.category,
            name: response.name,
            close: response.close,
            storeImageUrls: response.storeImageUrls,
            hashTags: response.hashTags,
            longitude: response.geolocation.longitude,
            latitude: response.geolocation.latitude,
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: OrderMenuDTO) -> OrderMenuEntity {
        OrderMenuEntity(
            menu: toEntity(response.menu),
            quantity: response.quantity
        )
    }

    static func toEntity(_ response: OrderMenuDetail) -> OrderMenuDetailEntity {
        OrderMenuDetailEntity(
            id: response.id,
            category: response.category,
            name: response.name,
            description: response.description,
            originInformation: response.originInformation,
            price: response.price,
            tags: response.tags,
            menuImageUrl: response.menuImageUrl,
            createdAt: response.createdAt.toDate(),
            updatedAt: response.updatedAt.toDate()
        )
    }

    static func toEntity(_ response: OrderStatusTimelineDTO) -> OrderStatusTimelineEntity {
        OrderStatusTimelineEntity(
            status: OrderStatusEntity(rawValue: response.status) ?? .pendingApproval,
            completed: response.completed,
            changedAt: response.changedAt?.toDate()
        )
    }

    static func toEntity(_ response: OrderReviewItem?) -> OrderReviewEntity? {
        guard let response else { return nil }
        return OrderReviewEntity(
            id: response.id,
            rating: response.rating
        )
    }
}
