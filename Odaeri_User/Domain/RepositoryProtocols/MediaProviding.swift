//
//  MediaProviding.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation

protocol MediaProviding {
    func makeAsset(for entity: VideoEntity, stream: VideoStreamEntity?) -> AVAsset?
    func makeAsset(for url: URL) -> AVAsset?
}
