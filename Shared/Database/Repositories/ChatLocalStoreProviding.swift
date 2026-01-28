//
//  ChatLocalStoreProviding.swift
//  Odaeri
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation
import Combine

protocol ChatLocalStoreProviding {
    func observeMessagesPublisher(roomId: String, ascending: Bool) -> AnyPublisher<[ChatEntity], Never>
    func observeRoomsPublisher() -> AnyPublisher<[ChatRoomEntity], Never>
    func saveMessage(_ entity: ChatEntity) -> AnyPublisher<Bool, Never>
    func saveMessages(_ entities: [ChatEntity]) -> AnyPublisher<Bool, Never>
    func saveRoom(_ entity: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    func saveMessageWithRoomUpdate(
        _ entity: ChatEntity,
        isRead: Bool,
        shouldIncrementUnread: Bool,
        currentUserId: String
    ) -> AnyPublisher<Bool, Never>
    func saveTempMessage(
        tempId: String,
        roomId: String,
        content: String,
        sender: ChatParticipantEntity,
        files: [String],
        uploadProgress: Float
    ) -> AnyPublisher<Bool, Never>
    func updateMessageId(from tempId: String, to realEntity: ChatEntity) -> AnyPublisher<Bool, Never>
    func updateMessageStatus(chatId: String, status: ChatMessageStatus) -> AnyPublisher<Bool, Never>
    func updateUploadProgress(chatId: String, progress: Float) -> AnyPublisher<Bool, Never>
    func deleteMessage(chatId: String) -> AnyPublisher<Bool, Never>
    func fetchMessage(chatId: String) -> AnyPublisher<ChatEntity?, Never>
    func markSendingMessagesFailed(roomId: String) -> AnyPublisher<Bool, Never>
    func markAllMessagesAsRead(roomId: String) -> AnyPublisher<Bool, Never>
    func hasAnyUnreadRoom() -> AnyPublisher<Bool, Never>
    func latestMessageCreatedAt(roomId: String) -> String?
    func oldestMessageCreatedAt(roomId: String) -> String?
}
