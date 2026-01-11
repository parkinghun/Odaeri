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

    init(chatRepository: ChatRepository = ChatRepositoryImpl()) {
        self.chatRepository = chatRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let didPop: AnyPublisher<Void, Never>
        let roomSelected: AnyPublisher<ChatRoomEntity, Never>
    }

    struct Output {
        let chatRooms: AnyPublisher<[ChatRoomEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let chatRoomsSubject = CurrentValueSubject<[ChatRoomEntity], Never>([])

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchChatRooms(subject: chatRoomsSubject)
            }
            .store(in: &cancellables)

        input.didPop
            .sink { [weak self] _ in
                self?.coordinator?.finish()
            }
            .store(in: &cancellables)

        input.roomSelected
            .sink { [weak self] room in
                self?.openChatRoom(from: room)
            }
            .store(in: &cancellables)

        return Output(
            chatRooms: chatRoomsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func fetchChatRooms(subject: CurrentValueSubject<[ChatRoomEntity], Never>) {
        isLoadingSubject.send(true)

        chatRepository.fetchChatRooms()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { rooms in
                    subject.send(rooms)
                }
            )
            .store(in: &cancellables)
    }

    private func openChatRoom(from room: ChatRoomEntity) {
        let currentUserId = UserManager.shared.currentUser?.userId ?? "current_user"
        guard let opponent = room.participants.first(where: { $0.userId != currentUserId }) else {
            coordinator?.showChatRoom(roomId: room.roomId, title: "알 수 없음")
            return
        }

        coordinator?.showChatRoom(roomId: room.roomId, title: opponent.nick)
    }
}
