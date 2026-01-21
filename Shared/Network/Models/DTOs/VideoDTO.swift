//
//  VideoDTO.swift
//  Odaeri
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct VideoListResponse: Decodable {
    let data: [VideoResponse]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct VideoResponse: Decodable {
    let videoId: String
    let fileName: String
    let title: String
    let description: String
    let duration: Double
    let thumbnailUrl: String
    let availableQualities: [String]
    let viewCount: Int
    let likeCount: Int
    let isLiked: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case videoId = "id"
        case fileName = "file_name"
        case title, description, duration
        case thumbnailUrl = "thumbnail_url"
        case availableQualities = "available_qualities"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case createdAt
    }
}

struct VideoStreamResponse: Decodable {
    let videoId: String
    let streamUrl: String
    let qualities: [VideoStreamQualityResponse]
    let subtitles: [VideoSubtitleResponse]

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case streamUrl = "stream_url"
        case qualities, subtitles
    }
}

struct VideoStreamQualityResponse: Decodable {
    let quality: String
    let url: String
}

struct VideoSubtitleResponse: Decodable {
    let language: String
    let name: String
    let isDefault: Bool
    let url: String

    enum CodingKeys: String, CodingKey {
        case language, name, url
        case isDefault = "is_default"
    }
}
