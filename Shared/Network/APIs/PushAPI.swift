//
//  PushAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum PushAPI {
    case registerPushToken(token: String, deviceId: String)
    case unregisterPushToken(deviceId: String)
    case getPushSettings
    case updatePushSettings(orderNotification: Bool?, communityNotification: Bool?, marketingNotification: Bool?)
    case getPushHistory(page: Int, limit: Int)
}

extension PushAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .registerPushToken:
            return "/push/register"
        case .unregisterPushToken:
            return "/push/unregister"
        case .getPushSettings, .updatePushSettings:
            return "/push/settings"
        case .getPushHistory:
            return "/push/history"
        }
    }

    var method: Moya.Method {
        switch self {
        case .registerPushToken, .unregisterPushToken:
            return .post
        case .getPushSettings, .getPushHistory:
            return .get
        case .updatePushSettings:
            return .patch
        }
    }

    var task: Task {
        switch self {
        case let .registerPushToken(token, deviceId):
            return .requestParameters(
                parameters: [
                    "token": token,
                    "deviceId": deviceId
                ],
                encoding: JSONEncoding.default
            )

        case let .unregisterPushToken(deviceId):
            return .requestParameters(
                parameters: ["deviceId": deviceId],
                encoding: JSONEncoding.default
            )

        case .getPushSettings:
            return .requestPlain

        case let .updatePushSettings(orderNotification, communityNotification, marketingNotification):
            var parameters = [String: Any]()
            if let orderNotification = orderNotification {
                parameters["orderNotification"] = orderNotification
            }
            if let communityNotification = communityNotification {
                parameters["communityNotification"] = communityNotification
            }
            if let marketingNotification = marketingNotification {
                parameters["marketingNotification"] = marketingNotification
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case let .getPushHistory(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )
        }
    }
}
