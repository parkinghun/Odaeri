//
//  ReviewAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum StoreReviewAPI {
    case createReview(storeId: String, request: StoreReviewRequest)
    case fetchReviews(storeId: String, next: String?, limit: Int?, orderBy: String?)
    case fetchReviewDetail(storeId: String, reviewId: String)
    case updateReview(storeId: String, reviewId: String, request: StoreReviewRequest)
    case deleteReview(storeId: String, reviewId: String)
    case fetchReviewRatings(storeId: String)
}

extension StoreReviewAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createReview(let storeId, _),
                .fetchReviews(let storeId, _, _, _):
            return "/stores/\(storeId)/reviews"
            
        case .fetchReviewDetail(let storeId, let reviewId),
                .updateReview(let storeId, let reviewId, _),
                .deleteReview(let storeId, let reviewId):
            return "/stores/\(storeId)/reviews/\(reviewId)"
            
        case .fetchReviewRatings(let storeId):
            return "/stores/\(storeId)/reviews/reviews-ratings"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .createReview:
            return .post
        case .fetchReviews, .fetchReviewDetail, .fetchReviewRatings:
            return .get
        case .updateReview:
            return .put
        case .deleteReview:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case let .createReview(_, request):
            return .requestJSONEncodable(request)

        case let .fetchReviews(_, next, limit, orderBy):
            var params: [String: Any] = [:]
            if let next = next, !next.isEmpty { params["next"] = next }
            params["limit"] = limit ?? 5
            params["order_by"] = orderBy ?? "latest"
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .fetchReviewDetail, .fetchReviewRatings, .deleteReview:
            return .requestPlain

        case let .updateReview(_, _, request):
            return .requestJSONEncodable(request)
        }
    }
}
