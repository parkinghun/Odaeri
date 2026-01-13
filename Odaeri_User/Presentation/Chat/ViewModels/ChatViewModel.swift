//
//  ChatViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation
import Combine
import RealmSwift
import UniformTypeIdentifiers

final class ChatViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: ChatCoordinator?
    private let chatRepository: ChatRepository
    let roomId: String
    private let currentUserId: String
    private let currentUserName: String
    let title: String?
    private let networkMonitor = NetworkMonitor.shared

    private var realmToken: NotificationToken?
    private let chatItemsSubject = CurrentValueSubject<[ChatItem], Never>([])
    private var sendTimeouts: [String: DispatchWorkItem] = [:]
    private var uploadCancellables: [String: AnyCancellable] = [:]
    private var isSyncing = false

    private var currentLimit = 30
    private var isInitialLoading = true
    private var isFetchingNextPage = false
    private var hasMoreLocalData = true
    private var hasMoreRemoteData = true
    private let pageSize = 30
    private var detectedGaps: Set<String> = []

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let sendMessage: AnyPublisher<SendMessagePayload, Never>
    }

    struct Output {
        let chatItems: AnyPublisher<[ChatItem], Never>
        let isLoadingMore: AnyPublisher<Bool, Never>
    }

    private let isLoadingMoreSubject = CurrentValueSubject<Bool, Never>(false)

    struct SendMessagePayload {
        let content: String
        let attachments: [ChatInputAttachmentItem]
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
                self?.setupNetworkObserver()
                self?.setupReconnectionObserver()
            }
            .store(in: &cancellables)

        input.sendMessage
            .sink { [weak self] payload in
                self?.sendMessage(payload)
            }
            .store(in: &cancellables)

        return Output(
            chatItems: chatItemsSubject.eraseToAnyPublisher(),
            isLoadingMore: isLoadingMoreSubject.eraseToAnyPublisher()
        )
    }

    private func setupRealmObserver() {
        let messages = RealmChatRepository.shared.observeMessagesDescending(roomId: roomId)

        realmToken = messages?.observe { [weak self] changes in
            guard let self = self else { return }

            switch changes {
            case let .initial(results):
                self.isInitialLoading = false
                self.updateChatItems(from: results)
            case let .update(results, _, _, _):
                self.updateChatItems(from: results)
            case let .error(error):
                print("Realm 메시지 관찰 오류: \(error)")
            }
        }
    }

    private func updateChatItems(from results: Results<ChatMessageObject>) {
        let totalCount = results.count
        hasMoreLocalData = totalCount > currentLimit

        let limitedResults = results.prefix(currentLimit)
        let entities = limitedResults.map { $0.toEntity() }
        let reversedEntities = Array(entities.reversed())

        detectAndFillGaps(in: reversedEntities)

        let items = ChatMapper.map(reversedEntities, currentUserId: currentUserId)
        chatItemsSubject.send(items)
    }

    private func detectAndFillGaps(in entities: [ChatEntity]) {
        guard entities.count > 1 else { return }

        for i in 0..<(entities.count - 1) {
            let current = entities[i]
            let next = entities[i + 1]

            guard let currentDate = DateFormatter.iso8601.date(from: current.createdAt),
                  let nextDate = DateFormatter.iso8601.date(from: next.createdAt) else {
                continue
            }

            let timeDifference = nextDate.timeIntervalSince(currentDate)
            let gapThreshold: TimeInterval = 300

            if timeDifference > gapThreshold {
                let gapKey = "\(current.createdAt)-\(next.createdAt)"
                if !detectedGaps.contains(gapKey) {
                    detectedGaps.insert(gapKey)
                    fillGap(from: current.createdAt, to: next.createdAt)
                }
            }
        }
    }

    private func fillGap(from startDate: String, to endDate: String) {
        chatRepository.fetchChatHistory(roomId: roomId, next: startDate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Gap filling failed: \(error)")
                    }
                },
                receiveValue: { [weak self] entities in
                    guard let self = self else { return }

                    let filteredEntities = entities.filter { entity in
                        guard let entityDate = DateFormatter.iso8601.date(from: entity.createdAt),
                              let start = DateFormatter.iso8601.date(from: startDate),
                              let end = DateFormatter.iso8601.date(from: endDate) else {
                            return false
                        }
                        return entityDate > start && entityDate < end
                    }

                    if !filteredEntities.isEmpty {
                        self.saveMessagesToRealm(filteredEntities)
                    }
                }
            )
            .store(in: &cancellables)
    }

    func loadMoreMessages() {
        guard !isFetchingNextPage, !isInitialLoading else { return }

        if hasMoreLocalData {
            isFetchingNextPage = true
            isLoadingMoreSubject.send(true)
            currentLimit += pageSize
            isFetchingNextPage = false
            isLoadingMoreSubject.send(false)
        } else if hasMoreRemoteData {
            fetchOlderMessagesFromServer()
        }
    }

    private func fetchOlderMessagesFromServer() {
        guard !isFetchingNextPage, hasMoreRemoteData else { return }

        isFetchingNextPage = true
        isLoadingMoreSubject.send(true)

        let oldestCreatedAt = RealmChatRepository.shared.oldestMessageCreatedAt(roomId: roomId)

        chatRepository.fetchChatHistory(roomId: roomId, next: oldestCreatedAt)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isFetchingNextPage = false
                    self.isLoadingMoreSubject.send(false)

                    if case .failure = completion {
                        self.hasMoreRemoteData = false
                    }
                },
                receiveValue: { [weak self] entities in
                    guard let self = self else { return }

                    if entities.isEmpty {
                        self.hasMoreRemoteData = false
                    } else {
                        self.saveMessagesToRealm(entities)
                        self.currentLimit += self.pageSize
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func syncMessagesFromServer() {
        guard !isSyncing else {
            print("이미 동기화 중: 요청 무시")
            return
        }

        isSyncing = true
        print("동기화 시작: \(roomId)")

        let latestCreatedAt = RealmChatRepository.shared.latestMessageCreatedAt(roomId: roomId)
        let latestCreatedAtDate = latestCreatedAt.flatMap { DateFormatter.iso8601.date(from: $0) }

        chatRepository.fetchChatHistory(roomId: roomId, next: latestCreatedAt)
            .sink(
                receiveCompletion: { [weak self] completion in
                    defer { self?.isSyncing = false }

                    if case .failure(let error) = completion {
                        print("채팅 히스토리 로드 실패: \(error)")
                        print("동기화 종료 (실패)")
                    } else {
                        print("동기화 완료")
                    }
                },
                receiveValue: { [weak self] entities in
                    guard let self = self else { return }
                    let filtered = self.filterNewMessages(entities, after: latestCreatedAtDate)
                    print("동기화된 새 메시지: \(filtered.count)개")
                    self.saveMessagesToRealm(filtered)
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

    private func setupNetworkObserver() {
        networkMonitor.isConnectedPublisher
            .removeDuplicates()
            .sink { [weak self] isConnected in
                guard let self = self, !isConnected else { return }
                RealmChatRepository.shared.markSendingMessagesFailed(roomId: self.roomId)
                    .sink { _ in }
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)
    }

    private func setupReconnectionObserver() {
        ChatSocketService.shared.reconnectionPublisher
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .filter { [weak self] reconnectedRoomId in
                guard let self = self else { return false }
                return reconnectedRoomId == self.roomId && !self.isSyncing
            }
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("재연결 감지: \(self.roomId) 동기화 시작")
                self.syncMessagesFromServer()
            }
            .store(in: &cancellables)
    }

    private func filterNewMessages(
        _ entities: [ChatEntity],
        after latestCreatedAtDate: Date?
    ) -> [ChatEntity] {
        guard let latestCreatedAtDate = latestCreatedAtDate else {
            return entities
        }

        return entities.filter { entity in
            guard let createdAtDate = DateFormatter.iso8601.date(from: entity.createdAt) else {
                return true
            }
            return createdAtDate > latestCreatedAtDate
        }
    }

    private func sendMessage(_ payload: SendMessagePayload) {
        let content = payload.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = payload.attachments
        guard !content.isEmpty || !attachments.isEmpty else { return }

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
            files: attachments.compactMap { $0.localURLString }
        )
        .sink { success in
            print("임시 메시지 저장 \(success ? "성공" : "실패")")
        }
        .store(in: &cancellables)

        sendMessageFromStored(
            tempId: tempId,
            content: content,
            files: attachments.compactMap { $0.localURLString }
        )
    }

    private func updateMessageStatus(tempId: String, status: ChatMessageStatus) {
        RealmChatRepository.shared.updateMessageStatus(chatId: tempId, status: status)
            .sink { _ in }
            .store(in: &cancellables)
    }

    private func updateUploadProgress(tempId: String, progress: Float) {
        RealmChatRepository.shared.updateUploadProgress(chatId: tempId, progress: progress)
            .sink { _ in }
            .store(in: &cancellables)
    }

    private func updateTempMessageToReal(tempId: String, realMessage: ChatEntity) {
        cancelTimeout(for: tempId)
        RealmChatRepository.shared.updateMessageId(from: tempId, to: realMessage)
            .sink { success in
                if success {
                    print("임시 메시지를 실제 메시지로 교체 완료: \(tempId) → \(realMessage.chatId)")
                }
            }
            .store(in: &cancellables)
    }

    func retryMessage(messageId: String) {
        RealmChatRepository.shared.fetchMessage(chatId: messageId)
            .sink { [weak self] entity in
                guard let self = self, let entity = entity else { return }
                self.updateMessageStatus(tempId: messageId, status: .sending)
                self.updateUploadProgress(tempId: messageId, progress: 0)
                self.sendMessageFromStored(
                    tempId: messageId,
                    content: entity.content,
                    files: entity.files
                )
            }
            .store(in: &cancellables)
    }

    func deleteMessage(messageId: String) {
        cancelTimeout(for: messageId)
        uploadCancellables[messageId]?.cancel()
        uploadCancellables.removeValue(forKey: messageId)

        RealmChatRepository.shared.fetchMessage(chatId: messageId)
            .sink { [weak self] entity in
                guard let self = self else { return }
                if let entity = entity {
                    self.removeLocalFiles(from: entity.files)
                }
                RealmChatRepository.shared.deleteMessage(chatId: messageId)
                    .sink { _ in }
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)
    }

    private func sendMessageFromStored(
        tempId: String,
        content: String,
        files: [String]
    ) {
        scheduleTimeout(for: tempId)

        let uploadFiles = buildUploadFiles(from: files)
        if !files.isEmpty && uploadFiles.count != files.count {
            updateMessageStatus(tempId: tempId, status: .failed)
            cancelTimeout(for: tempId)
            return
        }

        if uploadFiles.isEmpty {
            chatRepository.sendChat(roomId: roomId, content: content, files: [])
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.updateMessageStatus(tempId: tempId, status: .failed)
                            self?.cancelTimeout(for: tempId)
                        }
                    },
                    receiveValue: { [weak self] realMessage in
                        self?.updateTempMessageToReal(tempId: tempId, realMessage: realMessage)
                    }
                )
                .store(in: &cancellables)
            return
        }

        let uploadCancellable = chatRepository.uploadChatFiles(
            roomId: roomId,
            files: uploadFiles,
            progress: { [weak self] progress in
                self?.updateUploadProgress(tempId: tempId, progress: Float(progress))
            }
        )
        .flatMap { [weak self] urls -> AnyPublisher<ChatEntity, NetworkError> in
            guard let self = self else {
                return Empty(completeImmediately: true)
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
            return self.chatRepository.sendChat(roomId: self.roomId, content: content, files: urls)
        }
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.updateMessageStatus(tempId: tempId, status: .failed)
                    self?.cancelTimeout(for: tempId)
                }
                self?.uploadCancellables.removeValue(forKey: tempId)
            },
            receiveValue: { [weak self] realMessage in
                self?.updateTempMessageToReal(tempId: tempId, realMessage: realMessage)
                self?.uploadCancellables.removeValue(forKey: tempId)
            }
        )
        uploadCancellables[tempId] = uploadCancellable
    }

    private func scheduleTimeout(for tempId: String) {
        cancelTimeout(for: tempId)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.updateMessageStatus(tempId: tempId, status: .failed)
            self.uploadCancellables[tempId]?.cancel()
            self.uploadCancellables.removeValue(forKey: tempId)
        }
        sendTimeouts[tempId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: workItem)
    }

    private func cancelTimeout(for tempId: String) {
        if let workItem = sendTimeouts[tempId] {
            workItem.cancel()
            sendTimeouts.removeValue(forKey: tempId)
        }
    }

    private func removeLocalFiles(from fileStrings: [String]) {
        fileStrings.forEach { fileString in
            guard let url = URL(string: fileString), url.isFileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func buildUploadFiles(from fileStrings: [String]) -> [ChatUploadFile] {
        return fileStrings.compactMap { fileString in
            guard let url = URL(string: fileString) else { return nil }
            let fileName = url.lastPathComponent.isEmpty ? "chat_file" : url.lastPathComponent
            let mimeType = mimeType(for: url)
            return ChatUploadFile(source: .file(url), fileName: fileName, mimeType: mimeType)
        }
    }

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            break
        }
        if let type = UTType(filenameExtension: ext) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}
