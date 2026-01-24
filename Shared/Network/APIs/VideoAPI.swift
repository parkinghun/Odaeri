//
//  VideoAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum VideoAPI {
    case fetchVideoList(next: String?, limit: Int?)
    case getVideoStreamingURL(videoId: String)
    case toggleVideoLike(videoId: String, status: Bool)
    case getSubtitleFile(path: String)
}

extension VideoAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .fetchVideoList:
            return "/videos"
        case let .getVideoStreamingURL(videoId):
            return "/videos/\(videoId)/stream"
        case let .toggleVideoLike(videoId, _):
            return "/videos/\(videoId)/like"
        case let .getSubtitleFile(path):
            return path
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchVideoList, .getVideoStreamingURL, .getSubtitleFile:
            return .get
        case .toggleVideoLike:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .fetchVideoList(next, limit):
            var params: [String: Any] = [:]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getVideoStreamingURL, .getSubtitleFile:
            return .requestPlain
        case let .toggleVideoLike(_, status):
            return .requestCustomJSONEncodable(LikeStatusRequest(likeStatus: status), encoder: .init())
        }
    }
}
