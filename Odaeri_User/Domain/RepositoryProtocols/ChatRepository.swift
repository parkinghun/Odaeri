//
//  ChatRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import Foundation
import Combine

protocol ChatRepository {
    func createOrGetChatRoom(opponentId: String) -> AnyPublisher<ChatRoomEntity, NetworkError>
    func fetchChatRooms() -> AnyPublisher<[ChatRoomEntity], NetworkError>
    func sendChat(roomId: String, content: String, files: [String]) -> AnyPublisher<ChatEntity, NetworkError>
    func fetchChatHistory(roomId: String, next: String?) -> AnyPublisher<[ChatEntity], NetworkError>
}
