//
//  StoreDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum StoreDTOMapper {
    static func toEntity(_ response: StoreResponse) -> StoreEntity {
        StoreEntity(
            storeId: response.storeId,
            name: response.name,
            category: response.category,
            description: response.description,
            address: response.address,
            longitude: response.geolocation.longitude,
            latitude: response.geolocation.latitude,
            open: response.open,
            close: response.close,
            estimatedPickupTime: response.estimatedPickupTime,
            parkingGuide: response.parkingGuide,
            storeImageUrls: response.storeImageUrls,
            hashTags: response.hashTags,
            isPicchelin: response.isPicchelin,
            isPick: response.isPick,
            pickCount: response.pickCount,
            totalReviewCount: response.totalReviewCount,
            totalOrderCount: response.totalOrderCount,
            totalRating: response.totalRating,
            creator: toEntity(response.creator),
            menuList: response.menuList.map(MenuDTOMapper.toEntity)
        )
    }

    static func toEntity(_ summary: StoreSummary) -> StoreEntity {
        StoreEntity(
            storeId: summary.storeId,
            name: summary.name,
            category: summary.category,
            description: "",
            address: "",
            longitude: summary.geolocation.longitude,
            latitude: summary.geolocation.latitude,
            open: "",
            close: summary.close,
            estimatedPickupTime: nil,
            parkingGuide: "",
            storeImageUrls: summary.storeImageUrls,
            hashTags: summary.hashTags,
            isPicchelin: summary.isPicchelin,
            isPick: summary.isPick,
            pickCount: summary.pickCount,
            totalReviewCount: summary.totalReviewCount,
            totalOrderCount: summary.totalOrderCount,
            totalRating: summary.totalRating,
            creator: nil,
            menuList: []
        )
    }

    static func toEntity(_ creator: Creator) -> CreatorEntity {
        CreatorEntity(
            userId: creator.userId,
            nick: creator.nick,
            profileImage: creator.profileImage
        )
    }

    static func toEntity(_ geolocation: Geolocation) -> GeolocationEntity {
        GeolocationEntity(
            longitude: geolocation.longitude,
            latitude: geolocation.latitude
        )
    }
}
