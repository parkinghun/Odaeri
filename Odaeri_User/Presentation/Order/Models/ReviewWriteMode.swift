//
//  ReviewWriteMode.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation

enum ReviewWriteMode {
    case create(order: OrderListItemEntity)
    case edit(order: OrderListItemEntity)

    var order: OrderListItemEntity {
        switch self {
        case .create(let order), .edit(let order):
            return order
        }
    }

    var navigationTitle: String {
        switch self {
        case .create:
            return "리뷰 작성"
        case .edit:
            return "리뷰 수정"
        }
    }

    var actionTitle: String {
        switch self {
        case .create:
            return "리뷰 작성하기"
        case .edit:
            return "리뷰 수정하기"
        }
    }

    var initialRating: Int {
        order.review?.rating ?? 0
    }
}
