//
//  ChatAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum ChatAPI {
    case getChatRooms(page: Int, limit: Int)
    case getChatRoomDetail(roomId: Int)
    case createChatRoom(storeId: Int)
    case getMessages(roomId: Int, page: Int, limit: Int)
    case sendMessage(roomId: Int, content: String, messageType: String)
    case deleteChatRoom(roomId: Int)
}

extension ChatAPI: BaseAPI {
    var path: String {
        switch self {
        case .getChatRooms:
            return "/chats/rooms"
        case .getChatRoomDetail(let roomId):
            return "/chats/rooms/\(roomId)"
        case .createChatRoom:
            return "/chats/rooms"
        case .getMessages(let roomId, _, _):
            return "/chats/rooms/\(roomId)/messages"
        case .sendMessage(let roomId, _, _):
            return "/chats/rooms/\(roomId)/messages"
        case .deleteChatRoom(let roomId):
            return "/chats/rooms/\(roomId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createChatRoom, .sendMessage:
            return .post
        case .getChatRooms, .getChatRoomDetail, .getMessages:
            return .get
        case .deleteChatRoom:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case let .getChatRooms(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case .getChatRoomDetail:
            return .requestPlain

        case let .createChatRoom(storeId):
            return .requestParameters(
                parameters: ["storeId": storeId],
                encoding: JSONEncoding.default
            )

        case let .getMessages(_, page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )

        case let .sendMessage(_, content, messageType):
            return .requestParameters(
                parameters: [
                    "content": content,
                    "messageType": messageType
                ],
                encoding: JSONEncoding.default
            )

        case .deleteChatRoom:
            return .requestPlain
        }
    }
}
