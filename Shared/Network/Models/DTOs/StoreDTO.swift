//
//  StoreDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/27/25.
//

import Foundation

// MARK: - Generic Response
struct StoreListResponse: Decodable {
    let data: [StoreSummary]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

// MARK: - Store Models
struct StoreSummary: Decodable {
    let storeId: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let hashTags: [String]
    let totalRating: Double
    let totalOrderCount: Int
    let totalReviewCount: Int
    let geolocation: Geolocation
    let distance: Double?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case id
        case category, name, close, distance, createdAt, updatedAt
        case storeImageUrls = "store_image_urls"
        case isPicchelin = "is_picchelin"
        case isPick = "is_pick"
        case pickCount = "pick_count"
        case hashTags, totalRating = "total_rating", totalOrderCount = "total_order_count", totalReviewCount = "total_review_count", geolocation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let storeId = try? container.decode(String.self, forKey: .storeId) {
            self.storeId = storeId
        } else {
            self.storeId = try container.decode(String.self, forKey: .id)
        }
        self.category = try container.decode(String.self, forKey: .category)
        self.name = try container.decode(String.self, forKey: .name)
        self.close = try container.decode(String.self, forKey: .close)
        self.storeImageUrls = try container.decode([String].self, forKey: .storeImageUrls)
        self.isPicchelin = try container.decode(Bool.self, forKey: .isPicchelin)
        self.isPick = try container.decode(Bool.self, forKey: .isPick)
        self.pickCount = try container.decode(Int.self, forKey: .pickCount)
        self.hashTags = try container.decode([String].self, forKey: .hashTags)
        self.totalRating = try container.decode(Double.self, forKey: .totalRating)
        self.totalOrderCount = try container.decode(Int.self, forKey: .totalOrderCount)
        self.totalReviewCount = try container.decode(Int.self, forKey: .totalReviewCount)
        self.geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        self.distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

struct Geolocation: Decodable {
    let longitude: Double
    let latitude: Double
}

struct LikeStatusRequest: Codable {
    let likeStatus: Bool
    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

// MARK: - Review Models
struct ReviewResponse: Decodable {
    let data: [ReviewItem]
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct ReviewItem: Decodable {
    let reviewId: String
    let content: String
    let rating: Int
    let store: StoreSummary
    let reviewImageUrls: [String]
    let orderMenuList: [String]
    let creator: Creator
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case reviewId = "review_id", content, rating, store, createdAt
        case reviewImageUrls = "review_image_urls"
        case orderMenuList = "order_menu_list"
        case creator
    }
}

struct Creator: Codable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

// MARK: - Popular Keywords
struct PopularKeywordsResponse: Decodable {
    let data: [String]
}

// MARK: - Admin Request Models
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

// MARK: - Admin Response Models
struct StoreImageUploadResponse: Decodable {
    let imageUrls: [String]

    enum CodingKeys: String, CodingKey {
        case imageUrls = "store_image_urls"
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

// MARK: - Empty Response
struct EmptyResponse: Decodable {}
