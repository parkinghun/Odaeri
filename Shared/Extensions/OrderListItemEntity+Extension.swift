//
//  OrderListItemEntity+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation

extension OrderListItemEntity {
    func updatingStatus(_ status: OrderStatusEntity, updatedAt: Date = Date()) -> OrderListItemEntity {
        OrderListItemEntity(
            orderId: orderId,
            orderCode: orderCode,
            totalPrice: totalPrice,
            review: review,
            store: store,
            orderMenuList: orderMenuList,
            currentOrderStatus: status,
            orderStatusTimeline: orderStatusTimeline,
            paidAt: paidAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
