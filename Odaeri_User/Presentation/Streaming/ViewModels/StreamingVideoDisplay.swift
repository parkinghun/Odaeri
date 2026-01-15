//
//  StreamingVideoDisplay.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import Foundation

struct StreamingVideoDisplay: Hashable {
    let videoId: String
    let title: String
    let description: String
    let likeCountText: String
    let viewCountText: String
    let isLiked: Bool
    let createdAtText: String
    let thumbnailUrl: String
}
