//
//  HLSMediaProvider.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation
import Foundation

final class HLSMediaProvider {
    func makeAsset(stream: VideoStreamEntity?) -> AVURLAsset? {
        guard let urlString = stream?.streamUrl,
              let url = URL(string: urlString) else { return nil }
        return makeAsset(url: url)
    }

    func makeAsset(url: URL) -> AVURLAsset? {
        guard url.pathExtension.lowercased() == "m3u8" else { return nil }
        return AVURLAsset(url: url)
    }
}
