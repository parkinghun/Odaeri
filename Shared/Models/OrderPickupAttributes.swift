//
//  OrderPickupAttributes.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import ActivityKit
import Foundation

struct OrderPickupAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: OrderStatusEntity
        var expectedTime: String
    }

    let storeName: String
    let orderNumber: String
}
