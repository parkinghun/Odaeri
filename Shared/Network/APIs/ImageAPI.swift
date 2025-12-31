//
//  ImageAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/29/25.
//

import Foundation
import Moya

enum ImageAPI {
    case fetchImage(path: String, etag: String? = nil)
}

extension ImageAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .fetchImage(let path, _):
            return path
        }
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

    var headerSet: HeaderSet {
        return .readImage
    }

    // ETag 지원을 위한 headers override
    var headers: [String: String]? {
        var headers = headerSet.toHeaders()

        // 304 응답을 위한 If-None-Match 헤더 추가
        if case .fetchImage(_, let etag) = self, let etag = etag {
            headers["If-None-Match"] = etag
        }

        return headers
    }
}

