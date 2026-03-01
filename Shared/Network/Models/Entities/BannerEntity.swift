//
//  BannerEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation

struct BannerEntity: Hashable, Equatable {
    let name: String
    let imageUrl: String
    let action: BannerAction

    init(
        name: String,
        imageUrl: String,
        action: BannerAction
    ) {
        self.name = name
        self.imageUrl = imageUrl
        self.action = action
    }

    static func == (lhs: BannerEntity, rhs: BannerEntity) -> Bool {
        lhs.name == rhs.name && lhs.imageUrl == rhs.imageUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(imageUrl)
    }
}

enum BannerAction: Hashable, Equatable {
    case webView(path: String)

    var isWebView: Bool {
        if case .webView = self {
            return true
        }
        return false
    }

    var webViewPath: String? {
        if case .webView(let path) = self {
            return path
        }
        return nil
    }
}
