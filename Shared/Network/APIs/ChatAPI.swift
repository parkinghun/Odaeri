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
    case uploadChatFiles(roomId: String, files: [ChatUploadFile])
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
        case .uploadChatFiles(let roomId, _):
            return "/chats/\(roomId)/files"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createOrGetChatRoom, .sendChat, .uploadChatFiles:
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

        case .uploadChatFiles(_, let files):
            var formData = [MultipartFormData]()
            for (index, file) in files.enumerated() {
                let fileName = file.fileName.isEmpty ? "chat_file_\(index)" : file.fileName
                let mimeType = file.mimeType.isEmpty ? "application/octet-stream" : file.mimeType

                switch file.source {
                case .data(let data):
                    formData.append(
                        MultipartFormData(
                            provider: .data(data),
                            name: "files",
                            fileName: fileName,
                            mimeType: mimeType
                        )
                    )
                case .file(let url):
                    formData.append(
                        MultipartFormData(
                            provider: .file(url),
                            name: "files",
                            fileName: fileName,
                            mimeType: mimeType
                        )
                    )
                }
            }
            return .uploadMultipart(formData)
        }
    }
    
    var headerSet: HeaderSet {
        switch self {
        case .uploadChatFiles:
            return .fileUpload
        default: return .authenticated
        }
    }
}
