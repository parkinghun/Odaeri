//
//  MenuEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

struct MenuEntity {
    let name: String
    let description: String
    let originInformation: String
    private let price: Int
    let category: String
    let tags: [String]
    let menuImageUrl: String
    private let isSoldOut: Bool
    
    var formattedPrice: String {
        return price.formatted() + "원"
    }

    init(
        name: String,
        description: String,
        originInformation: String,
        price: Int,
        category: String,
        tags: [String],
        menuImageUrl: String,
        isSoldOut: Bool = false,
    ) {
        self.name = name
        self.description = description
        self.originInformation = originInformation
        self.price = price
        self.category = category
        self.tags = tags
        self.menuImageUrl = menuImageUrl
        self.isSoldOut = isSoldOut
    }

    init(from response: MenuResponse) {
        self.name = response.name
        self.description = response.description
        self.originInformation = response.originInformation
        self.price = response.price
        self.category = response.category
        self.tags = response.tags
        self.menuImageUrl = response.menuImageUrl
        self.isSoldOut = response.isSoldOut
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
