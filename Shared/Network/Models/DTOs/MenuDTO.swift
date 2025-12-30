//
//  MenuDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import Foundation

// MARK: - Request Models
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
