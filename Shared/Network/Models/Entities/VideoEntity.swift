//
//  VideoEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation

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
        self.streamUrl = StreamURLNormalizer.normalize(response.streamUrl)
        self.qualities = response.qualities.map { VideoStreamQualityEntity(from: $0) }
        self.subtitles = response.subtitles.map { VideoSubtitleEntity(from: $0) }
    }
}

struct VideoStreamQualityEntity: Hashable, Equatable {
    let quality: String
    let url: String

    init(from response: VideoStreamQualityResponse) {
        self.quality = response.quality
        self.url = StreamURLNormalizer.normalize(response.url)
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

private enum StreamURLNormalizer {
    static func normalize(_ path: String) -> String {
        if path.hasPrefix("http") {
            return path
        }

        let baseURLString = APIEnvironment.current.baseURL.absoluteString
        let trimmedBase = baseURLString.hasSuffix("/")
        ? String(baseURLString.dropLast())
        : baseURLString
        let versionSuffix = "/\(APIEnvironment.current.version)"
        let base = trimmedBase.hasSuffix(versionSuffix)
        ? trimmedBase
        : "\(trimmedBase)\(versionSuffix)"

        var cleanPath = path
        if cleanPath.hasPrefix("./") { cleanPath.removeFirst(2) }
        if cleanPath.hasPrefix("/") { cleanPath.removeFirst() }

        return "\(base)/\(cleanPath)"
    }
}
