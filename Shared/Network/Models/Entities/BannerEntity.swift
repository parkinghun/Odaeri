//
//  BannerEntity.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import Foundation

struct BannerEntity {
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

    init(from item: BannerItem) {
        self.name = item.name
        self.imageUrl = item.imageUrl

        switch item.payload.type {
        case .webview:
            self.action = .webView(path: item.payload.value)
        }
    }
}

enum BannerAction {
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
