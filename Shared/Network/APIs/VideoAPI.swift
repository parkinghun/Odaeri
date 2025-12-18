//
//  VideoAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum VideoAPI {
    case getVideos(storeId: Int?, page: Int, limit: Int)
    case getVideoDetail(videoId: Int)
    case uploadVideo(storeId: Int, title: String, videoData: Data, thumbnailData: Data)
    case deleteVideo(videoId: Int)
    case likeVideo(videoId: Int)
    case unlikeVideo(videoId: Int)
}

extension VideoAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .getVideos:
            return "/videos"
        case .getVideoDetail(let videoId):
            return "/videos/\(videoId)"
        case .uploadVideo:
            return "/videos"
        case .deleteVideo(let videoId):
            return "/videos/\(videoId)"
        case .likeVideo(let videoId):
            return "/videos/\(videoId)/like"
        case .unlikeVideo(let videoId):
            return "/videos/\(videoId)/unlike"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadVideo, .likeVideo:
            return .post
        case .getVideos, .getVideoDetail:
            return .get
        case .deleteVideo, .unlikeVideo:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .getVideos(storeId, page, limit):
            var parameters: [String: Any] = ["page": page, "limit": limit]
            if let storeId = storeId {
                parameters["storeId"] = storeId
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )

        case .getVideoDetail:
            return .requestPlain

        case let .uploadVideo(storeId, title, videoData, thumbnailData):
            var formData = [MultipartFormData]()

            let storeIdData = "\(storeId)".data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(storeIdData), name: "storeId"))

            let titleData = title.data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(titleData), name: "title"))

            formData.append(
                MultipartFormData(
                    provider: .data(videoData),
                    name: "video",
                    fileName: "video.mp4",
                    mimeType: "video/mp4"
                )
            )

            formData.append(
                MultipartFormData(
                    provider: .data(thumbnailData),
                    name: "thumbnail",
                    fileName: "thumbnail.jpg",
                    mimeType: "image/jpeg"
                )
            )

            return .uploadMultipart(formData)

        case .deleteVideo, .likeVideo, .unlikeVideo:
            return .requestPlain
        }
    }
}
