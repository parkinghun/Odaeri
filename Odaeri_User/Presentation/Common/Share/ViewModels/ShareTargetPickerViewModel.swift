//
//  ShareTargetPickerViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation
import Combine

final class ShareTargetPickerViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let searchText: AnyPublisher<String, Never>
        let targetSelected: AnyPublisher<String, Never>
        let sendTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let items: AnyPublisher<[ShareTargetDisplayModel], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let emptyState: AnyPublisher<ShareTargetEmptyState?, Never>
        let isSendEnabled: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let didSend: AnyPublisher<Void, Never>
    }

    struct ShareTargetEmptyState {
        let title: String
        let subtitle: String
    }

    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let userManager: UserManager

    private let itemsSubject = CurrentValueSubject<[ShareTargetDisplayModel], Never>([])
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let emptyStateSubject = CurrentValueSubject<ShareTargetEmptyState?, Never>(nil)
    private let isSendEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let didSendSubject = PassthroughSubject<Void, Never>()

    private var chatTargets: [ShareTargetDisplayModel] = []
    private var roomIdByUserId: [String: String] = [:]
    private var selectedUserId: String?
    private var currentQuery = ""
    private var searchRequestCancellable: AnyCancellable?
    private let sharePayload: ShareCardPayload

    init(
        sharePayload: ShareCardPayload,
        chatRepository: ChatRepository,
        userRepository: UserRepository,
        userManager: UserManager
    ) {
        self.sharePayload = sharePayload
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.userManager = userManager
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchChatRooms()
            }
            .store(in: &cancellables)

        input.searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .filter { $0.isEmpty || $0.count >= 2 }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.currentQuery = query
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)

        input.targetSelected
            .sink { [weak self] userId in
                self?.selectTarget(userId: userId)
            }
            .store(in: &cancellables)

        input.sendTapped
            .sink { [weak self] _ in
                self?.sendShareCard()
            }
            .store(in: &cancellables)

        return Output(
            items: itemsSubject.eraseToAnyPublisher(),
            isLoading: loadingSubject.eraseToAnyPublisher(),
            emptyState: emptyStateSubject.eraseToAnyPublisher(),
            isSendEnabled: isSendEnabledSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            didSend: didSendSubject.eraseToAnyPublisher()
        )
    }

    private func fetchChatRooms() {
        loadingSubject.send(true)

        chatRepository.fetchChatRooms()
            .sink { [weak self] completion in
                self?.loadingSubject.send(false)
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            } receiveValue: { [weak self] rooms in
                self?.handleChatRooms(rooms)
            }
            .store(in: &cancellables)
    }

    private func handleChatRooms(_ rooms: [ChatRoomEntity]) {
        let currentUserId = userManager.currentUser?.userId ?? "current_user"
        var seen = Set<String>()
        var targets: [ShareTargetDisplayModel] = []
        var roomMap: [String: String] = [:]

        for room in rooms {
            guard let opponent = room.participants.first(where: { $0.userId != currentUserId }) else { continue }
            guard !seen.contains(opponent.userId) else { continue }

            seen.insert(opponent.userId)
            roomMap[opponent.userId] = room.roomId
            let profileImage = opponent.profileImage?.isEmpty == true ? nil : opponent.profileImage
            targets.append(
                ShareTargetDisplayModel(
                    userId: opponent.userId,
                    nick: opponent.nick,
                    profileImage: profileImage,
                    isSelected: opponent.userId == selectedUserId
                )
            )
        }

        roomIdByUserId = roomMap
        chatTargets = Array(targets.prefix(8))

        if currentQuery.isEmpty {
            updateItems(chatTargets)
        }
    }

    private func performSearch(query: String) {
        searchRequestCancellable?.cancel()

        guard !query.isEmpty else {
            updateItems(chatTargets)
            return
        }

        loadingSubject.send(true)

        searchRequestCancellable = userRepository.searchUsers(nick: query)
            .sink { [weak self] completion in
                self?.loadingSubject.send(false)
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            } receiveValue: { [weak self] results in
                self?.handleSearchResults(results)
            }
    }

    private func handleSearchResults(_ results: [UserSearchResult]) {
        let currentUserId = userManager.currentUser?.userId
        let targets = results
            .filter { $0.userId != currentUserId }
            .prefix(8)
            .map { result in
                ShareTargetDisplayModel(
                    userId: result.userId,
                    nick: result.nick,
                    profileImage: result.profileImage,
                    isSelected: result.userId == selectedUserId
                )
            }

        updateItems(Array(targets))
    }

    private func updateItems(_ items: [ShareTargetDisplayModel]) {
        if let selectedUserId, !items.contains(where: { $0.userId == selectedUserId }) {
            self.selectedUserId = nil
            isSendEnabledSubject.send(false)
        }

        itemsSubject.send(items)
        updateEmptyState(items: items)
    }

    private func updateEmptyState(items: [ShareTargetDisplayModel]) {
        if items.isEmpty {
            if currentQuery.isEmpty {
                emptyStateSubject.send(
                    ShareTargetEmptyState(
                        title: "공유할 채팅방이 없습니다.",
                        subtitle: "유저 검색을 통해 공유해보세요."
                    )
                )
            } else {
                emptyStateSubject.send(
                    ShareTargetEmptyState(
                        title: "검색 결과가 없습니다.",
                        subtitle: "다른 키워드로 다시 검색해보세요."
                    )
                )
            }
        } else {
            emptyStateSubject.send(nil)
        }
    }

    private func selectTarget(userId: String) {
        if selectedUserId == userId {
            selectedUserId = nil
            isSendEnabledSubject.send(false)
        } else {
            selectedUserId = userId
            isSendEnabledSubject.send(true)
        }

        let updatedItems = itemsSubject.value.map { item in
            ShareTargetDisplayModel(
                userId: item.userId,
                nick: item.nick,
                profileImage: item.profileImage,
                isSelected: item.userId == selectedUserId
            )
        }
        itemsSubject.send(updatedItems)
    }

    private func sendShareCard() {
        guard let targetUserId = selectedUserId else { return }
        guard !loadingSubject.value else { return }

        loadingSubject.send(true)

        let content = ShareCardMessageFormatter.makeContent(payload: sharePayload)
        let sendPublisher: AnyPublisher<ChatEntity, NetworkError>

        if let roomId = roomIdByUserId[targetUserId] {
            sendPublisher = chatRepository.sendChat(roomId: roomId, content: content, files: [])
        } else {
            sendPublisher = chatRepository.createOrGetChatRoom(opponentId: targetUserId)
                .flatMap { [weak self] room -> AnyPublisher<ChatEntity, NetworkError> in
                    guard let self else {
                        return Fail(error: NetworkError.unknown(NSError(domain: "ShareTargetPickerViewModel", code: -1)))
                            .eraseToAnyPublisher()
                    }
                    self.roomIdByUserId[targetUserId] = room.roomId
                    return self.chatRepository.sendChat(roomId: room.roomId, content: content, files: [])
                }
                .eraseToAnyPublisher()
        }

        sendPublisher
            .sink { [weak self] completion in
                self?.loadingSubject.send(false)
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            } receiveValue: { [weak self] _ in
                self?.didSendSubject.send(())
            }
            .store(in: &cancellables)
    }
}
