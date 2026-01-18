//
//  MediaUploadDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation

struct MediaFileUploadResponse: Decodable {
    let files: [String]
}

struct StoreReviewImageUploadResponse: Decodable {
    let reviewImageUrls: [String]

    enum CodingKeys: String, CodingKey {
        case reviewImageUrls = "review_image_urls"
    }
}
