//
//  MenuDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum MenuDTOMapper {
    static func toEntity(_ response: MenuResponse) -> MenuEntity {
        MenuEntity(
            menuId: response.menuId,
            name: response.name,
            description: response.description,
            originInformation: response.originInformation,
            price: response.price,
            category: response.category,
            tags: response.tags,
            menuImageUrl: response.menuImageUrl,
            isSoldOut: response.isSoldOut
        )
    }
}
