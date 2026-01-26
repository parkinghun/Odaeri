//
//  MediaUploadAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation
import Moya

enum MediaUploadAPI {
    case chatUpload(roomId: String, files: [MultipartFormData])
    case communityUpload(files: [MultipartFormData])
    case profileImageUpload(profile: MultipartFormData)
    case storeReviewUpload(storeId: String, files: [MultipartFormData])
    case storeUpload(files: [MultipartFormData])
    case menuUpload(files: [MultipartFormData])
}

extension MediaUploadAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case let .chatUpload(roomId, _):
            return "/chats/\(roomId)/files"
        case .communityUpload:
            return "/posts/files"
        case .profileImageUpload:
            return "/users/profile/image"
        case let .storeReviewUpload(storeId, _):
            return "/stores/\(storeId)/reviews/files"
        case .storeUpload:
            return "/stores/files"
        case .menuUpload:
            return "/menus/image"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        switch self {
        case .chatUpload(_, let files),
                .communityUpload(let files),
                .storeReviewUpload(_, let files),
                .storeUpload(let files),
                .menuUpload(let files):
            return .uploadMultipart(files)
        case .profileImageUpload(let profile):
            return .uploadMultipart([profile])
        }
    }
    
    var headerSet: HeaderSet {
        return .fileUpload
    }
}
