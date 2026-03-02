//
//  MenuEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

struct MenuEntity: Hashable {
    let menuId: String
    let name: String
    let description: String
    let originInformation: String
    private let price: Int
    let category: String
    let tags: [String]
    let menuImageUrl: String
    let isSoldOut: Bool

    var formattedPrice: String {
        return price.formatted() + "원"
    }

    var priceValue: Int {
        return price
    }

    init(
        menuId: String,
        name: String,
        description: String,
        originInformation: String,
        price: Int,
        category: String,
        tags: [String],
        menuImageUrl: String,
        isSoldOut: Bool = false
    ) {
        self.menuId = menuId
        self.name = name
        self.description = description
        self.originInformation = originInformation
        self.price = price
        self.category = category
        self.tags = tags
        self.menuImageUrl = menuImageUrl
        self.isSoldOut = isSoldOut
    }

    func toRequest() -> MenuRequest {
        return MenuRequest(
            name: name,
            description: description,
            originInformation: originInformation,
            price: price,
            category: category,
            tags: tags,
            menuImageUrl: menuImageUrl,
            isSoldOut: isSoldOut
        )
    }
}
