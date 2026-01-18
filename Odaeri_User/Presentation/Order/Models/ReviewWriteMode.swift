//
//  ReviewWriteMode.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation

enum ReviewWriteMode {
    case create(context: ReviewWriteContext)
    case edit(context: ReviewWriteContext, reviewId: String, initial: ReviewWriteInitialData)

    var context: ReviewWriteContext {
        switch self {
        case .create(let context), .edit(let context, _, _):
            return context
        }
    }

    var storeId: String {
        context.storeId
    }

    var storeName: String {
        context.storeName
    }

    var storeImageUrl: String? {
        context.storeImageUrl
    }

    var menuSummary: String {
        context.menuSummary
    }

    var orderCode: String? {
        context.orderCode
    }

    var reviewId: String? {
        switch self {
        case .create:
            return nil
        case .edit(_, let reviewId, _):
            return reviewId
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
        switch self {
        case .create:
            return 0
        case .edit(_, _, let initial):
            return initial.rating
        }
    }

    var initialContent: String {
        switch self {
        case .create:
            return ""
        case .edit(_, _, let initial):
            return initial.content
        }
    }

    var initialImageUrls: [String] {
        switch self {
        case .create:
            return []
        case .edit(_, _, let initial):
            return initial.imageUrls
        }
    }
}

struct ReviewWriteContext {
    let storeId: String
    let storeName: String
    let storeImageUrl: String?
    let menuNames: [String]
    let orderCode: String?

    var menuSummary: String {
        guard let first = menuNames.first else { return "메뉴 없음" }
        if menuNames.count > 1 {
            return "\(first) 외 \(menuNames.count - 1)건"
        }
        return first
    }

    static func from(order: OrderListItemEntity) -> ReviewWriteContext {
        let menuNames = order.orderMenuList.map { $0.menu.name }
        return ReviewWriteContext(
            storeId: order.store.id,
            storeName: order.store.name,
            storeImageUrl: order.store.storeImageUrls.first,
            menuNames: menuNames,
            orderCode: order.orderCode
        )
    }
}

struct ReviewWriteInitialData {
    let rating: Int
    let content: String
    let imageUrls: [String]
}
