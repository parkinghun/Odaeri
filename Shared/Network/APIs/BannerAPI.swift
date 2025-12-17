//
//  BannerAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum BannerAPI {
    case getBanners(location: String?)
    case getBannerDetail(bannerId: Int)
    case trackBannerClick(bannerId: Int)
}

extension BannerAPI: BaseAPI {
    var path: String {
        switch self {
        case .getBanners:
            return "/banners"
        case .getBannerDetail(let bannerId):
            return "/banners/\(bannerId)"
        case .trackBannerClick(let bannerId):
            return "/banners/\(bannerId)/click"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getBanners, .getBannerDetail:
            return .get
        case .trackBannerClick:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .getBanners(location):
            if let location = location {
                return .requestParameters(
                    parameters: ["location": location],
                    encoding: URLEncoding.queryString
                )
            }
            return .requestPlain

        case .getBannerDetail:
            return .requestPlain

        case .trackBannerClick:
            return .requestPlain
        }
    }
}
