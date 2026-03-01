//
//  VideoDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum VideoDTOMapper {
    static func toEntity(_ response: VideoResponse) -> VideoEntity {
        VideoEntity(
            videoId: response.videoId,
            fileName: response.fileName,
            title: response.title,
            description: response.description,
            duration: response.duration,
            thumbnailUrl: response.thumbnailUrl,
            availableQualities: response.availableQualities,
            viewCount: response.viewCount,
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            createdAt: response.createdAt.toDate()
        )
    }

    static func toEntity(_ response: VideoStreamResponse) -> VideoStreamEntity {
        VideoStreamEntity(
            videoId: response.videoId,
            streamUrl: StreamURLNormalizer.normalize(response.streamUrl),
            qualities: response.qualities.map(toEntity),
            subtitles: response.subtitles.map(toEntity)
        )
    }

    static func toEntity(_ response: VideoStreamQualityResponse) -> VideoStreamQualityEntity {
        VideoStreamQualityEntity(
            quality: response.quality,
            url: StreamURLNormalizer.normalize(response.url)
        )
    }

    static func toEntity(_ response: VideoSubtitleResponse) -> VideoSubtitleEntity {
        VideoSubtitleEntity(
            language: response.language,
            name: response.name,
            isDefault: response.isDefault,
            url: response.url
        )
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
