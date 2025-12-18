//
//  BannerDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation

// MARK: - Response Models
struct BannerResponse: Decodable {
    let data: [BannerItem]
}

struct BannerItem: Decodable {
    let name: String
    let imageUrl: String
    let payload: BannerPayload

    enum CodingKeys: String, CodingKey {
        case name
        case imageUrl
        case payload
    }
}

struct BannerPayload: Decodable {
    let type: BannerPayloadType
    let value: String
}

enum BannerPayloadType: String, Decodable {
    case webview = "WEBVIEW"
}
