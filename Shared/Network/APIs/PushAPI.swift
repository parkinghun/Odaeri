//
//  PushAPI.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Moya

enum PushAPI {
    case pushNotification(request: PushRequest)
}

extension PushAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .pushNotification:
            return "/notifications/push"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .pushNotification:
            return .post
        }
    }
    
    var task: Task {
        switch self {
        case let .pushNotification(request):
            return .requestJSONEncodable(request)
        }
    }
}
