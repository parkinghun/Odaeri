//
//  ChatAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum ChatAPI {
    case createOrGetChatRoom(request: CreateChatRoomRequest)
    case getChatRooms
    case sendChat(roomId: String, request: SendChatRequest)
    case getChatHistory(roomId: String, next: String?)
}

extension ChatAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .createOrGetChatRoom:
            return "/chats"
        case .getChatRooms:
            return "/chats"
        case .sendChat(let roomId, _):
            return "/chats/\(roomId)"
        case .getChatHistory(let roomId, _):
            return "/chats/\(roomId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createOrGetChatRoom, .sendChat:
            return .post
        case .getChatRooms, .getChatHistory:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .createOrGetChatRoom(let request):
            return .requestJSONEncodable(request)

        case .getChatRooms:
            return .requestPlain

        case .sendChat(_, let request):
            return .requestJSONEncodable(request)

        case .getChatHistory(_, let next):
            if let next = next {
                return .requestParameters(
                    parameters: ["next": next],
                    encoding: URLEncoding.queryString
                )
            } else {
                return .requestPlain
            }
        }
    }
}
