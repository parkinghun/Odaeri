//
//  MediaUploadResult.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation

struct MediaUploadResult {
    let uploadedURLs: [String]
    let thumbnailData: Data?
    let localTempURL: URL?
}
