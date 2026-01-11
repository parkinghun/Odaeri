//
//  ChatViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation
import Combine

final class ChatViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ChatCoordinator?
    private let chatRepository: ChatRepository
    private let roomId: String
    private let currentUserId: String
    private let currentUserName: String
    let title: String?

    private var chatEntities: [ChatEntity] = []
    private let chatItemsSubject = CurrentValueSubject<[ChatItem], Never>([])

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let sendMessage: AnyPublisher<String, Never>
    }

    struct Output {
        let chatItems: AnyPublisher<[ChatItem], Never>
    }

    init(
        chatRepository: ChatRepository,
        roomId: String,
        currentUserId: String,
        currentUserName: String = "나",
        title: String? = nil
    ) {
        self.chatRepository = chatRepository
        self.roomId = roomId
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.title = title
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.loadInitialMessages()
            }
            .store(in: &cancellables)

        input.sendMessage
            .sink { [weak self] message in
                self?.sendMessage(message)
            }
            .store(in: &cancellables)

        return Output(
            chatItems: chatItemsSubject.eraseToAnyPublisher()
        )
    }

    private func loadInitialMessages() {
        chatRepository.fetchChatHistory(roomId: roomId, next: nil)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("채팅 로드 실패: \(error)")
                    }
                },
                receiveValue: { [weak self] entities in
                    guard let self = self else { return }
                    self.chatEntities = entities
                    let items = ChatMapper.map(entities, currentUserId: self.currentUserId)
                    self.chatItemsSubject.send(items)
                }
            )
            .store(in: &cancellables)
    }

    private func sendMessage(_ content: String) {
        chatRepository.sendChat(roomId: roomId, content: content, files: [])
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("메시지 전송 실패: \(error)")
                    }
                },
                receiveValue: { [weak self] newMessage in
                    guard let self = self else { return }
                    self.chatEntities.append(newMessage)
                    let items = ChatMapper.map(self.chatEntities, currentUserId: self.currentUserId)
                    self.chatItemsSubject.send(items)
                }
            )
            .store(in: &cancellables)
    }
}
