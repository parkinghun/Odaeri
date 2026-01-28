//
//  ChatRoomViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import Foundation
import Combine

final class ChatRoomViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ChatCoordinator?

    private let chatRepository: ChatRepository
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    struct Input {
        let viewWillAppear: AnyPublisher<Void, Never>
        let didPop: AnyPublisher<Void, Never>
        let roomSelected: AnyPublisher<String, Never>
    }

    struct Output {
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        input.viewWillAppear
            .sink { [weak self] _ in
                self?.syncChatRooms()
            }
            .store(in: &cancellables)

        input.didPop
            .sink { [weak self] _ in
                self?.coordinator?.finish()
            }
            .store(in: &cancellables)

        input.roomSelected
            .sink { [weak self] roomId in
                self?.openChatRoom(roomId: roomId)
            }
            .store(in: &cancellables)

        return Output(
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func syncChatRooms() {
        isLoadingSubject.send(true)

        chatRepository.fetchChatRooms()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] rooms in
                    self?.saveChatRoomsToRealm(rooms)
                }
            )
            .store(in: &cancellables)
    }

    private func saveChatRoomsToRealm(_ rooms: [ChatRoomEntity]) {
        rooms.forEach { room in
            RealmChatRepository.shared.saveRoom(room)
                .sink { success in
                    if !success {
                        print("채팅방 저장 실패: \(room.roomId)")
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func openChatRoom(roomId: String) {
        guard let realmRoom = RealmChatRepository.shared.observeRooms()?
            .filter("roomId == %@", roomId)
            .first else {
            coordinator?.showChatRoom(roomId: roomId, title: "알 수 없음")
            return
        }

        let currentUserId = UserManager.shared.currentUser?.userId ?? "current_user"
        let participantEntities = Array(realmRoom.participants.map { $0.toEntity() })
        guard let opponent = participantEntities.first(where: { $0.userId != currentUserId }) else {
            coordinator?.showChatRoom(roomId: roomId, title: "알 수 없음")
            return
        }

        coordinator?.showChatRoom(roomId: roomId, title: opponent.nick)
    }
}
