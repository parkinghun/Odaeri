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
    private let mediaUploadManager: MediaUploadManager
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

    private var updateWorkItem: DispatchWorkItem?
    private var hasCompletedInitialLoad = false

    private enum MessageSendingState {
        case idle
        case uploading
        case sending
    }

    private var sendingStates: [String: MessageSendingState] = [:]
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
        mediaUploadManager: MediaUploadManager = .shared,
        currentUserName: String = "나",
        title: String? = nil
    ) {
        self.chatRepository = chatRepository
        self.roomId = roomId
        self.currentUserId = currentUserId
        self.mediaUploadManager = mediaUploadManager
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
                self.updateChatItems(from: results, isInitial: true)
            case let .update(results, _, _, _):
                self.updateChatItems(from: results, isInitial: false)
            case let .error(error):
                print("Realm 메시지 관찰 오류: \(error)")
            }
        }
    }

    private func updateChatItems(from results: Results<ChatMessageObject>, isInitial: Bool) {
        let totalCount = results.count
        hasMoreLocalData = totalCount > currentLimit

        let limitedResults = results.prefix(currentLimit)
        let entities = limitedResults.map { $0.toEntity() }
        let reversedEntities = Array(entities.reversed())

        detectAndFillGaps(in: reversedEntities)

        let items = ChatMapper.map(reversedEntities, currentUserId: currentUserId)

        if isInitial || !hasCompletedInitialLoad {
            updateWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.chatItemsSubject.send(items)
                self.hasCompletedInitialLoad = true
            }

            updateWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        } else {
            chatItemsSubject.send(items)
        }
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

            let messages = RealmChatRepository.shared.observeMessagesDescending(roomId: roomId)
            if let results = messages {
                updateChatItems(from: results, isInitial: false)
            }

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
        guard !isSyncing else { return }

        isSyncing = true

        let latestCreatedAt = RealmChatRepository.shared.latestMessageCreatedAt(roomId: roomId)
        let latestCreatedAtDate = latestCreatedAt.flatMap { DateFormatter.iso8601.date(from: $0) }

        chatRepository.fetchChatHistory(roomId: roomId, next: latestCreatedAt)
            .sink(
                receiveCompletion: { [weak self] completion in
                    defer { self?.isSyncing = false }

                    if case .failure(let error) = completion {
                        print("[ChatViewModel] 채팅 동기화 실패: \(error)")
                    }
                },
                receiveValue: { [weak self] entities in
                    guard let self = self else { return }
                    let filtered = self.filterNewMessages(entities, after: latestCreatedAtDate)
                    self.saveMessagesToRealm(filtered)
                }
            )
            .store(in: &cancellables)
    }

    private func saveMessagesToRealm(_ entities: [ChatEntity]) {
        RealmChatRepository.shared.saveMessages(entities)
            .sink { _ in }
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
        guard sendingStates[tempId] == nil || sendingStates[tempId] == .idle else {
            print("[ChatViewModel] 중복 전송 방지: \(tempId), 현재 상태: \(String(describing: sendingStates[tempId]))")
            return
        }

        scheduleTimeout(for: tempId)

        if files.isEmpty {
            sendChatWithoutFiles(tempId: tempId, content: content)
        } else {
            startTwoStepPipeline(tempId: tempId, content: content, localFiles: files)
        }
    }

    private func sendChatWithoutFiles(tempId: String, content: String) {
        print("[ChatViewModel] 순수 텍스트 메시지 전송 (Early Exit)")
        sendingStates[tempId] = .sending

        chatRepository.sendChat(roomId: roomId, content: content, files: [])
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }

                    if case .failure(let error) = completion {
                        print("[ChatViewModel] 메시지 전송 실패: \(error)")
                        self.updateMessageStatus(tempId: tempId, status: .failed)
                        self.cancelTimeout(for: tempId)
                    }

                    self.cleanupSendingState(for: tempId)
                },
                receiveValue: { [weak self] realMessage in
                    guard let self = self else { return }
                    print("[ChatViewModel] 메시지 전송 성공")
                    self.updateTempMessageToReal(tempId: tempId, realMessage: realMessage)
                    self.cleanupSendingState(for: tempId)
                }
            )
            .store(in: &cancellables)
    }

    private func startTwoStepPipeline(
        tempId: String,
        content: String,
        localFiles: [String]
    ) {
        print("[ChatViewModel] 2단계 파이프라인 시작")
        sendingStates[tempId] = .uploading

        print("[ChatViewModel] Step 1: 파일 업로드 (\(localFiles.count)개)")
        let uploadCancellable = mediaUploadManager.uploadFromPaths(
            localFiles,
            config: .chatDefault,
            roomId: roomId,
            progress: { [weak self] progress in
                self?.updateUploadProgress(tempId: tempId, progress: Float(progress))
            }
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                if case .failure(let error) = completion {
                    print("[ChatViewModel] Step 1 실패: 파일 업로드 에러 - \(error)")
                    self.updateMessageStatus(tempId: tempId, status: .failed)
                    self.cancelTimeout(for: tempId)
                    self.cleanupSendingState(for: tempId)
                    self.uploadCancellables.removeValue(forKey: tempId)
                }
            },
            receiveValue: { [weak self] uploadedURLs in
                guard let self = self else { return }

                print("[ChatViewModel] Step 1 성공: 파일 업로드 완료")
                print("  - 서버 URL: \(uploadedURLs)")

                print("  - Step 2: 메시지 전송")
                self.sendChatWithUploadedFiles(
                    tempId: tempId,
                    content: content,
                    uploadedURLs: uploadedURLs,
                    localFiles: localFiles
                )
            }
        )
        uploadCancellables[tempId] = uploadCancellable
    }

    private func sendChatWithUploadedFiles(
        tempId: String,
        content: String,
        uploadedURLs: [String],
        localFiles: [String]
    ) {
        sendingStates[tempId] = .sending

        chatRepository.sendChat(roomId: roomId, content: content, files: uploadedURLs)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }

                    if case .failure(let error) = completion {
                        print("[ChatViewModel] Step 2 실패: 메시지 전송 에러 - \(error)")
                        print("  - 업로드된 URL은 유효함, 재시도 가능")
                        self.updateMessageStatus(tempId: tempId, status: .failed)
                        self.cancelTimeout(for: tempId)
                    }

                    self.cleanupSendingState(for: tempId)
                    self.uploadCancellables.removeValue(forKey: tempId)
                },
                receiveValue: { [weak self] realMessage in
                    guard let self = self else { return }

                    print("[ChatViewModel] Step 2 성공: 메시지 전송 완료")
                    self.updateTempMessageToReal(tempId: tempId, realMessage: realMessage)
                    self.cleanupLocalFiles(tempId: tempId, files: localFiles)
                    self.cleanupSendingState(for: tempId)
                    self.uploadCancellables.removeValue(forKey: tempId)
                }
            )
            .store(in: &cancellables)
    }

    private func cleanupSendingState(for tempId: String) {
        sendingStates.removeValue(forKey: tempId)
    }

    private func cleanupLocalFiles(tempId: String, files: [String]) {
        print("[ChatViewModel] 로컬 파일 클린업 시작: \(files.count)개")
        files.forEach { fileName in
            FilePathManager.removeFile(fileName: fileName)
        }
        print("[ChatViewModel] 로컬 파일 클린업 완료")
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
        fileStrings.forEach { fileName in
            FilePathManager.removeFile(fileName: fileName)
        }
    }
}
