//
//  ImageAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/29/25.
//

import Foundation
import Moya

enum ImageAPI {
    case fetchImage(path: String)
}

extension ImageAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .fetchImage(let path):
            return path
        }
    }

    var headerSet: HeaderSet {
        return .readImage
    }

    var method: Moya.Method {
        switch self {
        case .fetchImage: .get
        }
    }

    var task: Task {
        switch self {
        case .fetchImage: .requestPlain
        }
    }
}

