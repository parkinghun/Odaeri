//
//  BannerAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum BannerAPI {
    case getBanners
}

extension BannerAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .getBanners:
            return "/banners/main"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getBanners:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getBanners:
            return .requestPlain
        }
    }
}
