//
//  ChatViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation
import Combine
import RealmSwift

final class ChatViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ChatCoordinator?
    private let chatRepository: ChatRepository
    let roomId: String
    private let currentUserId: String
    private let currentUserName: String
    let title: String?

    private var realmToken: NotificationToken?
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

    deinit {
        realmToken?.invalidate()
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.setupRealmObserver()
                self?.syncMessagesFromServer()
                self?.setupSocketObserver()
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

    private func setupRealmObserver() {
        let messages = RealmChatRepository.shared.observeMessages(roomId: roomId)

        realmToken = messages?.observe { [weak self] changes in
            guard let self = self else { return }

            switch changes {
            case .initial(let results):
                self.updateChatItems(from: results)
            case .update(let results, _, _, _):
                self.updateChatItems(from: results)
            case .error(let error):
                print("Realm 메시지 관찰 오류: \(error)")
            }
        }
    }

    private func updateChatItems(from results: Results<ChatMessageObject>) {
        let entities = results.map { $0.toEntity() }
        let items = ChatMapper.map(Array(entities), currentUserId: currentUserId)
        chatItemsSubject.send(items)
    }

    private func syncMessagesFromServer() {
        chatRepository.fetchChatHistory(roomId: roomId, next: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("채팅 히스토리 로드 실패: \(error)")
                    }
                },
                receiveValue: { [weak self] entities in
                    self?.saveMessagesToRealm(entities)
                }
            )
            .store(in: &cancellables)
    }

    private func saveMessagesToRealm(_ entities: [ChatEntity]) {
        RealmChatRepository.shared.saveMessages(entities)
            .sink { success in
                if success {
                    print("메시지 \(entities.count)개 Realm에 저장 완료")
                }
            }
            .store(in: &cancellables)
    }

    private func setupSocketObserver() {
        ChatSocketService.shared.messagesPublisher
            .sink { [weak self] newMessage in
                guard let self = self else { return }
                self.handleSocketMessage(newMessage)
            }
            .store(in: &cancellables)
    }

    private func handleSocketMessage(_ message: ChatEntity) {
        let isMyMessage = message.sender.userId == currentUserId

        RealmChatRepository.shared.saveMessageWithRoomUpdate(
            message,
            isRead: true,
            shouldIncrementUnread: !isMyMessage
        )
        .sink { success in
            if success {
                print("소켓 메시지 저장 완료: \(message.chatId)")
            }
        }
        .store(in: &cancellables)
    }

    private func sendMessage(_ content: String) {
        let tempId = "temp_\(UUID().uuidString)"
        let sender = ChatParticipantEntity(
            userId: currentUserId,
            nick: currentUserName,
            profileImage: UserManager.shared.currentUser?.profileImage ?? ""
        )

        RealmChatRepository.shared.saveTempMessage(
            tempId: tempId,
            roomId: roomId,
            content: content,
            sender: sender,
            files: []
        )
        .sink { _ in }
        .store(in: &cancellables)

        chatRepository.sendChat(roomId: roomId, content: content, files: [])
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("메시지 전송 실패: \(error)")
                        self?.updateMessageStatus(tempId: tempId, status: .error)
                    }
                },
                receiveValue: { [weak self] realMessage in
                    self?.updateTempMessageToReal(tempId: tempId, realMessage: realMessage)
                }
            )
            .store(in: &cancellables)
    }

    private func updateMessageStatus(tempId: String, status: ChatMessageStatus) {
        RealmChatRepository.shared.updateMessageStatus(chatId: tempId, status: status)
            .sink { _ in }
            .store(in: &cancellables)
    }

    private func updateTempMessageToReal(tempId: String, realMessage: ChatEntity) {
        RealmChatRepository.shared.updateMessageId(from: tempId, to: realMessage)
            .sink { success in
                if success {
                    print("임시 메시지를 실제 메시지로 교체 완료: \(tempId) → \(realMessage.chatId)")
                }
            }
            .store(in: &cancellables)
    }
}
