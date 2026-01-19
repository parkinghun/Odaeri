//
//  MediaItem.swift
//  Odaeri
//
//  Created by 박성훈 on 1/19/26.
//

import Foundation

struct MediaItem: Hashable {
    enum MediaType {
        case image
        case video
    }

    let type: MediaType
    let url: String
    let thumbnailUrl: String?

    init(type: MediaType, url: String, thumbnailUrl: String? = nil) {
        self.type = type
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }

    static func image(url: String) -> MediaItem {
        MediaItem(type: .image, url: url)
    }

    static func video(url: String, thumbnailUrl: String) -> MediaItem {
        MediaItem(type: .video, url: url, thumbnailUrl: thumbnailUrl)
    }
}
