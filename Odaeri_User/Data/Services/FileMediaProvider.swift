//
//  FileMediaProvider.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation

final class FileMediaProvider {
    private let mediaService: AppMediaService

    init(mediaService: AppMediaService = .shared) {
        self.mediaService = mediaService
    }

    func makeAsset(fileName: String) -> AVAsset? {
        guard let url = mediaService.resolvePlayableURL(for: fileName) else { return nil }
        return AVURLAsset(url: url)
    }

    func makeAsset(url: URL) -> AVAsset? {
        return AVURLAsset(url: url)
    }
}
