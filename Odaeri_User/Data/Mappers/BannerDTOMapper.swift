//
//  BannerDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum BannerDTOMapper {
    static func toEntity(_ item: BannerItem) -> BannerEntity {
        let action: BannerAction
        switch item.payload.type {
        case .webview:
            action = .webView(path: item.payload.value)
        }

        return BannerEntity(
            name: item.name,
            imageUrl: item.imageUrl,
            action: action
        )
    }
}
