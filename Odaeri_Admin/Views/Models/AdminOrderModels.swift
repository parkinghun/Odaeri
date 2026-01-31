//
//  AdminOrderModels.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import Foundation
import UIKit

enum OrderStatus: String {
    case pending = "PENDING_APPROVAL"
    case cooking = "COOKING"
    case completed = "PICKUP_COMPLETED"

    var displayName: String {
        switch self {
        case .pending: return "접수 대기"
        case .cooking: return "조리 중"
        case .completed: return "픽업 완료"
        }
    }

    var indicatorColor: UIColor {
        switch self {
        case .pending: return UIColor.systemRed
        case .cooking: return UIColor.systemBlue
        case .completed: return UIColor.systemGreen
        }
    }
}

struct Menu {
    let name: String
    let price: Int
    let quantity: Int
    let imageUrl: String?
}

struct Order {
    let orderCode: String
    let totalPrice: Int
    let status: OrderStatus
    let orderTime: Date
    let storeName: String
    let menus: [Menu]
}
