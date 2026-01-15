//
//  UnifiedMediaProvider.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation

final class UnifiedMediaProvider: MediaProviding {
    private let hlsProvider: HLSMediaProvider
    private let fileProvider: FileMediaProvider

    init(
        hlsProvider: HLSMediaProvider = HLSMediaProvider(),
        fileProvider: FileMediaProvider = FileMediaProvider()
    ) {
        self.hlsProvider = hlsProvider
        self.fileProvider = fileProvider
    }

    func makeAsset(for entity: VideoEntity, stream: VideoStreamEntity?) -> AVAsset? {
        switch entity.videoType {
        case .hls:
            return hlsProvider.makeAsset(stream: stream)
        case .file:
            return fileProvider.makeAsset(fileName: entity.fileName)
        }
    }

    func makeAsset(for url: URL) -> AVAsset? {
        return hlsProvider.makeAsset(url: url) ?? fileProvider.makeAsset(url: url)
    }
}
