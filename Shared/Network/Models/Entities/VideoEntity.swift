//
//  VideoEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

struct VideoListResult {
    let videos: [VideoEntity]
    let nextCursor: String?
}

enum VideoType {
    case hls
    case file
}

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
    var videoType: VideoType {
        if fileName.lowercased().hasSuffix(".m3u8") || !availableQualities.isEmpty {
            return .hls
        }
        return .file
    }

    var durationText: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        videoId: String,
        fileName: String,
        title: String,
        description: String,
        duration: Double,
        thumbnailUrl: String,
        availableQualities: [String],
        viewCount: Int,
        likeCount: Int,
        isLiked: Bool,
        createdAt: Date?
    ) {
        self.videoId = videoId
        self.fileName = fileName
        self.title = title
        self.description = description
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        self.availableQualities = availableQualities
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.createdAt = createdAt
    }
}

struct VideoStreamEntity: Hashable, Equatable {
    let videoId: String
    let streamUrl: String
    let qualities: [VideoStreamQualityEntity]
    let subtitles: [VideoSubtitleEntity]
}

struct VideoStreamQualityEntity: Hashable, Equatable {
    let quality: String
    let url: String
}

struct VideoSubtitleEntity: Hashable, Equatable {
    let language: String
    let name: String
    let isDefault: Bool
    let url: String
}
