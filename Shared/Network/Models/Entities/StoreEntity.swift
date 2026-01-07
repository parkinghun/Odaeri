//
//  StoreEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

struct StoreEntity: Hashable, Equatable {
    let storeId: String  // admin에서 필요함(가게 점주가 상태변경해줘야함)
    let name: String
    let category: String
    let description: String
    let address: String
    let longitude: Double
    let latitude: Double
    let open: String
    let close: String
    let estimatedPickupTime: Int?
    let parkingGuide: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let totalReviewCount: Int
    let totalOrderCount: Int
    let totalRating: Double
    let creator: CreatorEntity?
    let menuList: [MenuEntity]

    var rate: String {
        return String(format: "%.1f", totalRating)
    }
    
    init(
        storeId: String,
        name: String,
        category: String,
        description: String,
        address: String,
        longitude: Double,
        latitude: Double,
        open: String,
        close: String,
        estimatedPickupTime: Int? = nil,
        parkingGuide: String,
        storeImageUrls: [String],
        hashTags: [String],
        isPicchelin: Bool = false,
        isPick: Bool,
        pickCount: Int,
        totalReviewCount: Int,
        totalOrderCount: Int,
        totalRating: Double,
        creator: CreatorEntity,
        menuList: [MenuEntity],
    ) {
        self.storeId = storeId
        self.name = name
        self.category = category
        self.description = description
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
        self.open = open
        self.close = close
        self.estimatedPickupTime = estimatedPickupTime
        self.parkingGuide = parkingGuide
        self.storeImageUrls = storeImageUrls
        self.hashTags = hashTags
        self.isPicchelin = isPicchelin
        self.isPick = isPick
        self.pickCount = pickCount
        self.totalReviewCount = totalReviewCount
        self.totalOrderCount = totalOrderCount
        self.totalRating = totalRating
        self.creator = creator
        self.menuList = menuList
    }

    init(copying store: StoreEntity, isPick: Bool, pickCount: Int) {
        self.storeId = store.storeId
        self.name = store.name
        self.category = store.category
        self.description = store.description
        self.address = store.address
        self.longitude = store.longitude
        self.latitude = store.latitude
        self.open = store.open
        self.close = store.close
        self.estimatedPickupTime = store.estimatedPickupTime
        self.parkingGuide = store.parkingGuide
        self.storeImageUrls = store.storeImageUrls
        self.hashTags = store.hashTags
        self.isPicchelin = store.isPicchelin
        self.isPick = isPick
        self.pickCount = pickCount
        self.totalReviewCount = store.totalReviewCount
        self.totalOrderCount = store.totalOrderCount
        self.totalRating = store.totalRating
        self.creator = store.creator
        self.menuList = store.menuList
    }

    func updatingPick(isPick: Bool, pickCount: Int) -> StoreEntity {
        return StoreEntity(copying: self, isPick: isPick, pickCount: pickCount)
    }

    init(from response: StoreResponse) {
        self.storeId = response.storeId
        self.name = response.name
        self.category = response.category
        self.description = response.description
        self.address = response.address
        self.longitude = response.geolocation.longitude
        self.latitude = response.geolocation.latitude
        self.open = response.open
        self.close = response.close
        self.estimatedPickupTime = response.estimatedPickupTime
        self.parkingGuide = response.parkingGuide
        self.storeImageUrls = response.storeImageUrls
        self.hashTags = response.hashTags
        self.isPicchelin = response.isPicchelin
        self.isPick = response.isPick
        self.pickCount = response.pickCount
        self.totalReviewCount = response.totalReviewCount
        self.totalOrderCount = response.totalOrderCount
        self.totalRating = response.totalRating
        self.creator = CreatorEntity(from: response.creator)
        self.menuList = response.menuList.map { MenuEntity(from: $0) }
    }

    init(from summary: StoreSummary) {
        self.storeId = summary.storeId
        self.name = summary.name
        self.category = summary.category
        self.description = ""
        self.address = ""
        self.longitude = summary.geolocation.longitude
        self.latitude = summary.geolocation.latitude
        self.open = ""
        self.close = summary.close
        self.estimatedPickupTime = nil
        self.parkingGuide = ""
        self.storeImageUrls = summary.storeImageUrls
        self.hashTags = summary.hashTags
        self.isPicchelin = summary.isPicchelin
        self.isPick = summary.isPick
        self.pickCount = summary.pickCount
        self.totalReviewCount = summary.totalReviewCount
        self.totalOrderCount = summary.totalOrderCount
        self.totalRating = summary.totalRating
        #warning("creator, menulist 수정")
        self.creator = nil
        self.menuList = []
    }

    static func == (lhs: StoreEntity, rhs: StoreEntity) -> Bool {
        lhs.storeId == rhs.storeId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(storeId)
    }

    func toRequest() -> StoreRequest {
        return StoreRequest(
            name: name,
            category: category,
            description: description,
            address: address,
            longitude: longitude,
            latitude: latitude,
            open: open,
            close: close,
            parkingGuide: parkingGuide,
            storeImageUrls: storeImageUrls,
            hashTags: hashTags,
            isPicchelin: isPicchelin
        )
    }
}

struct CreatorEntity: Hashable, Equatable {
    let userId: String
    let nick: String
    let profileImage: String

    init(userId: String, nick: String, profileImage: String) {
        self.userId = userId
        self.nick = nick
        self.profileImage = profileImage
    }

    init(from creator: Creator) {
        self.userId = creator.userId
        self.nick = creator.nick
        self.profileImage = creator.profileImage
    }

    static func == (lhs: CreatorEntity, rhs: CreatorEntity) -> Bool {
        lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
