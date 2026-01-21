//
//  OrderListItemEntity+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation

extension OrderListItemEntity {
    func updatingStatus(_ status: OrderStatusEntity, updatedAt: Date = Date()) -> OrderListItemEntity {
        let dto = OrderListItem(
            orderId: orderId,
            orderCode: orderCode,
            totalPrice: totalPrice,
            review: makeReviewDTO(from: review),
            store: makeStoreDTO(from: store),
            orderMenuList: orderMenuList.map { makeMenuDTO(from: $0) },
            currentOrderStatus: status.rawValue,
            orderStatusTimeline: orderStatusTimeline.map { makeTimelineDTO(from: $0) },
            paidAt: paidAt.map { isoString(from: $0) },
            createdAt: isoString(from: createdAt ?? Date()),
            updatedAt: isoString(from: updatedAt)
        )
        return OrderListItemEntity(from: dto)
    }
}

private func makeReviewDTO(from entity: OrderReviewEntity?) -> OrderReviewItem? {
    guard let entity else { return nil }
    return OrderReviewItem(id: entity.id, rating: entity.rating)
}

private func makeStoreDTO(from entity: OrderStoreInfoEntity) -> OrderStoreInfo {
    OrderStoreInfo(
        id: entity.id,
        category: entity.category,
        name: entity.name,
        close: entity.close,
        storeImageUrls: entity.storeImageUrls,
        hashTags: entity.hashTags,
        geolocation: Geolocation(longitude: entity.longitude, latitude: entity.latitude),
        createdAt: isoString(from: entity.createdAt ?? Date()),
        updatedAt: isoString(from: entity.updatedAt ?? Date())
    )
}

private func makeMenuDTO(from entity: OrderMenuEntity) -> OrderMenuDTO {
    OrderMenuDTO(menu: makeMenuDetailDTO(from: entity.menu), quantity: entity.quantity)
}

private func makeMenuDetailDTO(from entity: OrderMenuDetailEntity) -> OrderMenuDetail {
    OrderMenuDetail(
        id: entity.id,
        category: entity.category,
        name: entity.name,
        description: entity.description,
        originInformation: entity.originInformation,
        price: entity.price,
        tags: entity.tags,
        menuImageUrl: entity.menuImageUrl,
        createdAt: isoString(from: entity.createdAt ?? Date()),
        updatedAt: isoString(from: entity.updatedAt ?? Date())
    )
}

private func makeTimelineDTO(from entity: OrderStatusTimelineEntity) -> OrderStatusTimelineDTO {
    OrderStatusTimelineDTO(
        status: entity.status.rawValue,
        completed: entity.completed,
        changedAt: entity.changedAt.map { isoString(from: $0) }
    )
}

private func isoString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}

