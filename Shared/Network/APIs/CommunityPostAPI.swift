//
//  CommunityPostAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum CommunityPostAPI {
    case getPosts(category: String?, page: Int, limit: Int)
    case getPostDetail(postId: Int)
    case createPost(title: String, content: String, category: String, images: [Data]?)
    case updatePost(postId: Int, title: String?, content: String?)
    case deletePost(postId: Int)
    case likePost(postId: Int)
    case unlikePost(postId: Int)
    case getMyPosts(page: Int, limit: Int)
}

extension CommunityPostAPI: BaseAPI {
    var path: String {
        switch self {
        case .getPosts:
            return "/community/posts"
        case .getPostDetail(let postId):
            return "/community/posts/\(postId)"
        case .createPost:
            return "/community/posts"
        case .updatePost(let postId, _, _):
            return "/community/posts/\(postId)"
        case .deletePost(let postId):
            return "/community/posts/\(postId)"
        case .likePost(let postId):
            return "/community/posts/\(postId)/like"
        case .unlikePost(let postId):
            return "/community/posts/\(postId)/unlike"
        case .getMyPosts:
            return "/community/posts/me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createPost, .likePost:
            return .post
        case .getPosts, .getPostDetail, .getMyPosts:
            return .get
        case .updatePost:
            return .patch
        case .deletePost, .unlikePost:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .getPosts(category, page, limit):
            var parameters: [String: Any] = ["page": page, "limit": limit]
            if let category = category {
                parameters["category"] = category
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )

        case .getPostDetail:
            return .requestPlain

        case let .createPost(title, content, category, images):
            var formData = [MultipartFormData]()

            let titleData = title.data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(titleData), name: "title"))

            let contentData = content.data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(contentData), name: "content"))

            let categoryData = category.data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(categoryData), name: "category"))

            if let images = images {
                for (index, imageData) in images.enumerated() {
                    formData.append(
                        MultipartFormData(
                            provider: .data(imageData),
                            name: "images",
                            fileName: "image\(index).jpg",
                            mimeType: "image/jpeg"
                        )
                    )
                }
            }

            return .uploadMultipart(formData)

        case let .updatePost(_, title, content):
            var parameters = [String: Any]()
            if let title = title {
                parameters["title"] = title
            }
            if let content = content {
                parameters["content"] = content
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case .deletePost, .likePost, .unlikePost:
            return .requestPlain

        case let .getMyPosts(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )
        }
    }
}
