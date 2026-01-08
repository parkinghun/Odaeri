//
//  CommunityPostAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum CommunityPostAPI {
    struct UploadFileRequest {
        let data: Data
        let fileName: String
        let mimeType: String
    }

    case uploadFiles(files: [UploadFileRequest])
    case createPost(request: CommunityPostCreateRequest)
    case updatePost(postId: String, request: CommunityPostUpdateRequest)
    case deletePost(postId: String)
    case likePost(postId: String, request: LikeStatusRequest)
    case fetchPostDetail(postId: String)
    case fetchPostsByGeolocation(
        category: String?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Int?,
        limit: Int?,
        next: String?,
        orderBy: String?
    )
    case searchPosts(title: String)
    case fetchPostsByUser(
        userId: String,
        category: String?,
        limit: Int?,
        next: String?
    )
    case fetchMyLikedPosts(
        category: String?,
        limit: Int?,
        next: String?
    )
}

extension CommunityPostAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .uploadFiles:
            return "/posts/files"
        case .createPost:
            return "/posts"
        case let .updatePost(postId, _):
            return "/posts/\(postId)"
        case let .deletePost(postId):
            return "/posts/\(postId)"
        case let .likePost(postId, _):
            return "/posts/\(postId)/like"
        case let .fetchPostDetail(postId):
            return "/posts/\(postId)"
        case .fetchPostsByGeolocation:
            return "/posts/geolocation"
        case .searchPosts:
            return "/posts/search"
        case let .fetchPostsByUser(userId, _, _, _):
            return "/posts/users/\(userId)"
        case .fetchMyLikedPosts:
            return "/posts/likes/me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadFiles, .createPost, .likePost:
            return .post
        case .updatePost:
            return .put
        case .deletePost:
            return .delete
        case .fetchPostDetail, .fetchPostsByGeolocation, .searchPosts, .fetchPostsByUser, .fetchMyLikedPosts:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .uploadFiles(files):
            let formData = files.map {
                MultipartFormData(
                    provider: .data($0.data),
                    name: "files",
                    fileName: $0.fileName,
                    mimeType: $0.mimeType
                )
            }
            return .uploadMultipart(formData)

        case let .createPost(request):
            return .requestCustomJSONEncodable(request, encoder: .init())

        case let .updatePost(_, request):
            var parameters: [String: Any] = [:]
            if let category = request.category { parameters["category"] = category }
            if let title = request.title { parameters["title"] = title }
            if let content = request.content { parameters["content"] = content }
            if let storeId = request.storeId { parameters["store_id"] = storeId }
            if let latitude = request.latitude { parameters["latitude"] = latitude }
            if let longitude = request.longitude { parameters["longitude"] = longitude }
            if let files = request.files { parameters["files"] = files }
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)

        case .deletePost, .fetchPostDetail:
            return .requestPlain

        case let .likePost(_, request):
            return .requestCustomJSONEncodable(request, encoder: .init())

        case let .fetchPostsByGeolocation(category, longitude, latitude, maxDistance, limit, next, orderBy):
            var parameters: [String: Any] = [:]
            if let category { parameters["category"] = category }
            if let longitude { parameters["longitude"] = longitude }
            if let latitude { parameters["latitude"] = latitude }
            if let maxDistance { parameters["maxDistance"] = maxDistance }
            if let limit { parameters["limit"] = limit }
            if let next { parameters["next"] = next }
            if let orderBy { parameters["order_by"] = orderBy }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)

        case let .searchPosts(title):
            return .requestParameters(parameters: ["title": title], encoding: URLEncoding.queryString)

        case let .fetchPostsByUser(_, category, limit, next):
            var parameters: [String: Any] = [:]
            if let category { parameters["category"] = category }
            if let limit { parameters["limit"] = limit }
            if let next { parameters["next"] = next }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)

        case let .fetchMyLikedPosts(category, limit, next):
            var parameters: [String: Any] = [:]
            if let category { parameters["category"] = category }
            if let limit { parameters["limit"] = limit }
            if let next { parameters["next"] = next }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        }
    }
    
    var headerSet: HeaderSet {
        switch self {
        case .uploadFiles:
            return .fileUpload
        default:
            return .authenticated
        }
    }
}
