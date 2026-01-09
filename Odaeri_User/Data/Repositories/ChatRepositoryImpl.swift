//
//  ChatRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import Foundation
import Combine
import Moya

final class ChatRepositoryImpl: ChatRepository {
    private let provider = ProviderFactory.makeChatProvider()
    private let useMockData = false

    func createOrGetChatRoom(opponentId: String) -> AnyPublisher<ChatRoomEntity, NetworkError> {
        let request = CreateChatRoomRequest(opponentId: opponentId)
        return provider.requestPublisher(.createOrGetChatRoom(request: request))
            .map { (response: ChatRoomResponse) in
                ChatRoomEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func fetchChatRooms() -> AnyPublisher<[ChatRoomEntity], NetworkError> {
        if useMockData {
            return loadMockChatRooms()
        }

        return provider.requestPublisher(.getChatRooms)
            .map { (response: ChatRoomListResponse) in
                response.data.map { ChatRoomEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func sendChat(roomId: String, content: String, files: [String]) -> AnyPublisher<ChatEntity, NetworkError> {
        let request = SendChatRequest(content: content, files: files)
        return provider.requestPublisher(.sendChat(roomId: roomId, request: request))
            .map { (response: ChatResponse) in
                ChatEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func fetchChatHistory(roomId: String, next: String?) -> AnyPublisher<[ChatEntity], NetworkError> {
        provider.requestPublisher(.getChatHistory(roomId: roomId, next: next))
            .map { (response: ChatListResponse) in
                response.data.map { ChatEntity(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func uploadChatFiles(roomId: String, files: [Data]) -> AnyPublisher<[String], NetworkError> {
        provider.requestPublisher(.uploadChatFiles(roomId: roomId, files: files))
            .map { (response: ChatFileUploadResponse) in
                response.files
            }
            .eraseToAnyPublisher()
    }

    private func loadMockChatRooms() -> AnyPublisher<[ChatRoomEntity], NetworkError> {
        guard let url = Bundle.main.url(forResource: "ChatRooms", withExtension: "json") else {
            return Fail(error: NetworkError.decodingFailed(MockDataError.fileNotFound))
                .eraseToAnyPublisher()
        }

        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(ChatRoomListResponse.self, from: data)
            let rooms = response.data.map { ChatRoomEntity(from: $0) }
            return Just(rooms)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: NetworkError.decodingFailed(error))
                .eraseToAnyPublisher()
        }
    }

    private enum MockDataError: Error {
        case fileNotFound
    }
}
