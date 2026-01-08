//
//  VideoEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct VideoEntity: Hashable, Equatable {
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
    let createdAt: Date?

    init(from response: VideoResponse) {
        self.videoId = response.videoId
        self.fileName = response.fileName
        self.title = response.title
        self.description = response.description
        self.duration = response.duration
        self.thumbnailUrl = response.thumbnailUrl
        self.availableQualities = response.availableQualities
        self.viewCount = response.viewCount
        self.likeCount = response.likeCount
        self.isLiked = response.isLiked
        self.createdAt = response.createdAt.toDate()
    }
}

struct VideoStreamEntity: Hashable, Equatable {
    let videoId: String
    let streamUrl: String
    let qualities: [VideoStreamQualityEntity]
    let subtitles: [VideoSubtitleEntity]

    init(from response: VideoStreamResponse) {
        self.videoId = response.videoId
        self.streamUrl = response.streamUrl
        self.qualities = response.qualities.map { VideoStreamQualityEntity(from: $0) }
        self.subtitles = response.subtitles.map { VideoSubtitleEntity(from: $0) }
    }
}

struct VideoStreamQualityEntity: Hashable, Equatable {
    let quality: String
    let url: String

    init(from response: VideoStreamQualityResponse) {
        self.quality = response.quality
        self.url = response.url
    }
}

struct VideoSubtitleEntity: Hashable, Equatable {
    let language: String
    let name: String
    let isDefault: Bool
    let url: String

    init(from response: VideoSubtitleResponse) {
        self.language = response.language
        self.name = response.name
        self.isDefault = response.isDefault
        self.url = response.url
    }
}
