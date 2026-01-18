//
//  MenuAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import Foundation
import Moya

enum MenuAPI {
    case uploadImage(imageData: MultipartFormData)
    case create(storeId: String, request: MenuRequest)
    case update(menuId: String, request: MenuRequest)
}

extension MenuAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .uploadImage:
            return "/menus/image"
        case .create(let storeId, _):
            return "/menus/stores/\(storeId)"
        case .update(let menuId, _):
            return "/menus/\(menuId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadImage, .create:
            return .post
        case .update:
            return .put
        }
    }

    var task: Task {
        switch self {
        case .uploadImage(let imageData):
            return .uploadMultipart([imageData])
        case .create(_, let request):
            return .requestJSONEncodable(request)
        case .update(_, let request):
            return .requestJSONEncodable(request)
        }
    }

    var headerSet: HeaderSet {
        switch self {
        case .uploadImage:
            return .fileUpload
        default:
            return .authenticated
        }
    }
}
