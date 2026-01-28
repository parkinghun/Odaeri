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
    private let chatLocalStore: ChatLocalStoreProviding
    private let userManager: UserManager
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let roomsSubject = CurrentValueSubject<[ChatRoomDisplayModel], Never>([])
    private var roomsObservationCancellable: AnyCancellable?
    private var latestRooms: [ChatRoomEntity] = []

    init(
        chatRepository: ChatRepository,
        chatLocalStore: ChatLocalStoreProviding,
        userManager: UserManager
    ) {
        self.chatRepository = chatRepository
        self.chatLocalStore = chatLocalStore
        self.userManager = userManager
    }

    struct Input {
        let viewWillAppear: AnyPublisher<Void, Never>
        let didPop: AnyPublisher<Void, Never>
        let roomSelected: AnyPublisher<String, Never>
    }

    struct Output {
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let rooms: AnyPublisher<[ChatRoomDisplayModel], Never>
    }

    func transform(input: Input) -> Output {
        input.viewWillAppear
            .sink { [weak self] _ in
                self?.startRoomObservation()
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
            error: errorSubject.eraseToAnyPublisher(),
            rooms: roomsSubject.eraseToAnyPublisher()
        )
    }

    private func startRoomObservation() {
        guard roomsObservationCancellable == nil else { return }

        roomsObservationCancellable = chatLocalStore.observeRoomsPublisher()
            .map { [weak self] entities -> [ChatRoomDisplayModel] in
                guard let self = self else { return [] }
                self.latestRooms = entities
                let currentUserId = self.userManager.currentUser?.userId ?? ""
                return ChatRoomMapper.map(entities, currentUserId: currentUserId)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                self?.roomsSubject.send(models)
            }
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
            chatLocalStore.saveRoom(room)
                .sink { success in
                    if !success {
                        print("채팅방 저장 실패: \(room.roomId)")
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func openChatRoom(roomId: String) {
        guard let room = latestRooms.first(where: { $0.roomId == roomId }) else {
            coordinator?.showChatRoom(roomId: roomId, title: "알 수 없음")
            return
        }

        let currentUserId = userManager.currentUser?.userId ?? "current_user"
        guard let opponent = room.participants.first(where: { $0.userId != currentUserId }) else {
            coordinator?.showChatRoom(roomId: roomId, title: "알 수 없음")
            return
        }

        coordinator?.showChatRoom(roomId: roomId, title: opponent.nick)
    }
}
