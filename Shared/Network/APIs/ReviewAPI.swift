//
//  ReviewAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum ReviewAPI {
    case createReview(orderId: Int, storeId: Int, rating: Int, content: String, images: [Data]?)
    case getStoreReviews(storeId: Int, page: Int, limit: Int)
    case getMyReviews(page: Int, limit: Int)
    case updateReview(reviewId: Int, rating: Int?, content: String?)
    case deleteReview(reviewId: Int)
    case likeReview(reviewId: Int)
    case unlikeReview(reviewId: Int)
}

extension ReviewAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createReview:
            return "/reviews"
        case .getStoreReviews(let storeId, _, _):
            return "/stores/\(storeId)/reviews"
        case .getMyReviews:
            return "/reviews/me"
        case .updateReview(let reviewId, _, _):
            return "/reviews/\(reviewId)"
        case .deleteReview(let reviewId):
            return "/reviews/\(reviewId)"
        case .likeReview(let reviewId):
            return "/reviews/\(reviewId)/like"
        case .unlikeReview(let reviewId):
            return "/reviews/\(reviewId)/unlike"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createReview, .likeReview:
            return .post
        case .getStoreReviews, .getMyReviews:
            return .get
        case .updateReview:
            return .patch
        case .deleteReview, .unlikeReview:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .createReview(orderId, storeId, rating, content, images):
            var formData = [MultipartFormData]()

            let orderIdData = "\(orderId)".data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(orderIdData), name: "orderId"))

            let storeIdData = "\(storeId)".data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(storeIdData), name: "storeId"))

            let ratingData = "\(rating)".data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(ratingData), name: "rating"))

            let contentData = content.data(using: .utf8)!
            formData.append(MultipartFormData(provider: .data(contentData), name: "content"))

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

        case let .getStoreReviews(_, page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .getMyReviews(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .updateReview(_, rating, content):
            var parameters = [String: Any]()
            if let rating = rating {
                parameters["rating"] = rating
            }
            if let content = content {
                parameters["content"] = content
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case .deleteReview, .likeReview, .unlikeReview:
            return .requestPlain
        }
    }
}
