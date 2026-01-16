//
//  MediaAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/29/25.
//

import Foundation
import Moya

enum MediaAPI {
    case fetchImage(path: String, etag: String? = nil)
    case downloadMedia(fullURL: String)
    case downloadMediaToDisk(fullURL: String, destination: URL)
}

extension MediaAPI: TargetType {
    var baseURL: URL {
        switch self {
        case .fetchImage:
            return APIEnvironment.current.baseURL
        case .downloadMedia(let fullURL), .downloadMediaToDisk(let fullURL, _):
            return URL(string: fullURL) ?? APIEnvironment.current.baseURL
        }
    }

    var path: String {
        switch self {
        case .fetchImage(let path, _):
            return "/\(APIEnvironment.current.version)\(path)"
        case .downloadMedia, .downloadMediaToDisk:
            return ""
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .fetchImage, .downloadMedia:
            return .requestPlain
        case .downloadMediaToDisk(_, let destination):
            let downloadDestination: DownloadDestination = { _, _ in
                return (destination, [.removePreviousFile, .createIntermediateDirectories])
            }
            return .downloadDestination(downloadDestination)
        }
    }
    
    var headers: [String: String]? {
        return HeaderSet.mediaRead.toHeaders()
    }

    var validationType: ValidationType {
        return .successCodes
    }

    var sampleData: Data {
        return Data()
    }
}

