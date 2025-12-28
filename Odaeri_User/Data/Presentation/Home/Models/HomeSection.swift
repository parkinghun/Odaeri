//
//  HomeSection.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import Foundation

enum HomeSection: Int, CaseIterable {
    case trendingRestaurants
    case banner
    case myPickupStores

    var title: String {
        switch self {
        case .trendingRestaurants: return "실시간 인기 맛집"
        case .banner: return ""
        case .myPickupStores: return "내가 픽업 가게"
        }
    }
}

enum HomeSectionItem: Hashable, Equatable {
    case trendingRestaurant(StoreEntity)
    case banner(BannerEntity)
    case myPickupStore(StoreEntity)
}

