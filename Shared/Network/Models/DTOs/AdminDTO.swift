//
//  AdminDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

// MARK: - Request Models
struct StoreRequest: Encodable {
    let name: String?
    let category: String?
    let description: String?
    let address: String?
    let longitude: Double?
    let latitude: Double?
    let open: String?
    let close: String?
    let parkingGuide: String?
    let storeImageUrls: [String]?
    let hashTags: [String]?
    let isPicchelin: Bool?

    enum CodingKeys: String, CodingKey {
        case name, category, description, address, longitude, latitude, open, close
        case parkingGuide = "parking_guide"
        case storeImageUrls = "store_image_urls"
        case hashTags
        case isPicchelin = "is_picchelin"
    }
}

struct MenuRequest: Encodable {
    let name: String?
    let description: String?
    let originInformation: String?
    let price: Int?
    let category: String?
    let tags: [String]?
    let menuImageUrl: String?
    let isSoldOut: Bool?

    enum CodingKeys: String, CodingKey {
        case name, description, price, category, tags
        case originInformation = "origin_information"
        case menuImageUrl = "menu_image_url"
        case isSoldOut = "is_sold_out"
    }
}

// MARK: - Response Models
struct StoreImageUploadResponse: Decodable {
    let imageUrls: [String]

    enum CodingKeys: String, CodingKey {
        case imageUrls = "store_image_urls"
    }
}

struct MenuResponse: Decodable {
    let menuId: String
    let storeId: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let isSoldOut: Bool
    let tags: [String]
    let menuImageUrl: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case storeId = "store_id"
        case category, name, description, price, tags
        case originInformation = "origin_information"
        case isSoldOut = "is_sold_out"
        case menuImageUrl = "menu_image_url"
        case createdAt, updatedAt
    }
}

struct MenuImageUploadResponse: Decodable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "menu_image_url"
    }
}

struct StoreResponse: Decodable {
    let storeId: String
    let category: String
    let name: String
    let description: String
    let hashTags: [String]
    let open: String
    let close: String
    let address: String
    let estimatedPickupTime: Int
    let parkingGuide: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let totalReviewCount: Int
    let totalOrderCount: Int
    let totalRating: Double
    let creator: Creator
    let geolocation: Geolocation
    let menuList: [MenuResponse]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case category, name, description, open, close, address
        case hashTags
        case estimatedPickupTime = "estimated_pickup_time"
        case parkingGuide = "parking_guide"
        case storeImageUrls = "store_image_urls"
        case isPicchelin = "is_picchelin"
        case isPick = "is_pick"
        case pickCount = "pick_count"
        case totalReviewCount = "total_review_count"
        case totalOrderCount = "total_order_count"
        case totalRating = "total_rating"
        case creator, geolocation
        case menuList = "menu_list"
        case createdAt, updatedAt
    }
}

struct Creator: Decodable {
    let userId: String
    let nick: String
    let profileImage: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

struct Geolocation: Decodable {
    let longitude: Double
    let latitude: Double
}
