//
//  StoreAPI+Admin.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import Foundation
import Moya

extension StoreAPI.Admin: BaseAPI {
    var endpoint: String {
        switch self {
        case .uploadImages:
            return "/stores/files"
        case .create:
            return "/stores"
        case .update(let storeId, _):
            return "/stores/\(storeId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadImages, .create:
            return .post
        case .update:
            return .put
        }
    }

    var task: Task {
        switch self {
        case .uploadImages(let files):
            return .uploadMultipart(files)
        case .create(let request):
            return .requestJSONEncodable(request)
        case .update(_, let request):
            return .requestJSONEncodable(request)
        }
    }

    var headerSet: HeaderSet {
        switch self {
        case .uploadImages:
            return .fileUpload
        default:
            return .authenticated
        }
    }
}
