//
//  RealmChatRepository.swift
//  Odaeri
//
//  Created by 박성훈 on 1/11/26.
//

import Foundation
import RealmSwift
import Combine

enum RealmError: Error {
    case missingUserSession
}

final class RealmChatRepository: ChatLocalStoreProviding {
    static let shared = RealmChatRepository(
        provider: RealmConfigurationProvider(),
        session: UserManager.shared
    )

    private let realmQueue = DispatchQueue(label: "com.odaeri.realm", qos: .userInitiated)
    private var processingMessageIds: Set<String> = []
    private let provider: RealmConfigurationProviding
    private let session: SessionProviding

    init(provider: RealmConfigurationProviding, session: SessionProviding) {
        self.provider = provider
        self.session = session
    }

    private func getRealm() throws -> Realm {
        guard let userId = session.currentUserId else {
            throw RealmError.missingUserSession
        }

        let config = try provider.configuration(for: userId)
        return try Realm(configuration: config)
    }

    @discardableResult
    func saveMessage(_ entity: ChatEntity) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    guard let object = ChatMessageObject.from(entity: entity) else {
                        promise(.success(false))
                        return
                    }

                    try realm?.write {
                        realm?.add(object, update: .all)
                    }

                    promise(.success(true))
                } catch {
                    print("메시지 저장 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func saveMessages(_ entities: [ChatEntity]) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    let objects = entities.compactMap { ChatMessageObject.from(entity: $0) }

                    try realm?.write {
                        objects.forEach { object in
                            realm?.add(object, update: .all)
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func saveMessageWithRoomUpdate(
        _ entity: ChatEntity,
        isRead: Bool,
        shouldIncrementUnread: Bool,
        currentUserId: String
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                guard let self = self else { return }
                if self.processingMessageIds.contains(entity.chatId) {
                    promise(.success(true))
                    return
                }
                self.processingMessageIds.insert(entity.chatId)
                defer { self.processingMessageIds.remove(entity.chatId) }

                do {
                    let realm = try self.getRealm()

                    guard let messageObject = ChatMessageObject.from(entity: entity, isRead: isRead) else {
                        promise(.success(false))
                        return
                    }

                    try realm.write {
                        if entity.sender.userId == currentUserId {
                            let sendingMessages = realm.objects(ChatMessageObject.self)
                                .filter("roomId == %@ AND statusRaw == %@", entity.roomId, ChatMessageStatus.sending.rawValue)

                            for msg in sendingMessages {
                                var shouldDelete = false

                                if !entity.content.isEmpty && msg.content == entity.content {
                                    shouldDelete = true
                                } else if !entity.files.isEmpty && !msg.files.isEmpty {
                                    let msgFiles = Set(msg.files.map { $0 })
                                    let entityFiles = Set(entity.files)
                                    if msgFiles == entityFiles {
                                        shouldDelete = true
                                    }
                                }

                                if shouldDelete {
                                    realm.delete(msg)
                                    break
                                }
                            }
                        }

                        if realm.object(ofType: ChatMessageObject.self, forPrimaryKey: entity.chatId) == nil {
                            realm.add(messageObject, update: .all)
                        }

                        if let room = realm.object(
                            ofType: ChatRoomObject.self,
                            forPrimaryKey: entity.roomId
                        ) {
                            room.lastChatContent = entity.content
                            room.lastChatCreatedAt = entity.createdAt
                            room.updatedAt = entity.createdAt

                            if let updatedAtDate = DateFormatter.iso8601.date(from: entity.createdAt) {
                                room.updatedAtDate = updatedAtDate
                            }

                            if shouldIncrementUnread {
                                room.hasUnread = true
                                room.unreadCount += 1
                            }
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func saveTempMessage(
        tempId: String,
        roomId: String,
        content: String,
        sender: ChatParticipantEntity,
        files: [String] = [],
        uploadProgress: Float = 0
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    let now = Date()
                    let createdAtString = DateFormatter.iso8601.string(from: now)

                    let object = ChatMessageObject()
                    object.chatId = tempId
                    object.roomId = roomId
                    object.content = content
                    object.createdAt = createdAtString
                    object.createdAtDate = now
                    object.updatedAt = createdAtString
                    object.sender = ChatParticipantObject.from(entity: sender)
                    object.files.append(objectsIn: files)
                    object.status = .sending
                    object.uploadProgress = uploadProgress
                    object.isRead = true

                    try realm?.write {
                        realm?.add(object)
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func updateMessageId(
        from tempId: String,
        to realEntity: ChatEntity
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        let tempMessage = realm?.object(
                            ofType: ChatMessageObject.self,
                            forPrimaryKey: tempId
                        )

                        let existingReal = realm?.object(
                            ofType: ChatMessageObject.self,
                            forPrimaryKey: realEntity.chatId
                        )

                        if let existingReal = existingReal {
                            existingReal.status = .sent
                            existingReal.uploadProgress = 1
                            if let tempMessage = tempMessage {
                                realm?.delete(tempMessage)
                            }
                            promise(.success(true))
                            return
                        }

                        let mergedContent = realEntity.content.isEmpty
                            ? (tempMessage?.content ?? "")
                            : realEntity.content

                        let mergedFiles = realEntity.files.isEmpty
                            ? (tempMessage?.files.map { $0 } ?? [])
                            : realEntity.files

                        if let tempMessage = tempMessage {
                            realm?.delete(tempMessage)
                        } else if let realm = realm {
                            let sendingMessages = realm.objects(ChatMessageObject.self)
                                .filter("roomId == %@ AND statusRaw == %@", realEntity.roomId, ChatMessageStatus.sending.rawValue)

                            for msg in sendingMessages {
                                if !msg.content.isEmpty && msg.content == realEntity.content {
                                    realm.delete(msg)
                                    break
                                } else if !msg.files.isEmpty && !mergedFiles.isEmpty {
                                    let msgFiles = Set(msg.files.map { $0 })
                                    let realFiles = Set(mergedFiles)
                                    if msgFiles == realFiles {
                                        realm.delete(msg)
                                        break
                                    }
                                }
                            }
                        }

                        let mergedEntity = ChatEntity(
                            chatId: realEntity.chatId,
                            roomId: realEntity.roomId,
                            content: mergedContent,
                            createdAt: realEntity.createdAt,
                            updatedAt: realEntity.updatedAt,
                            sender: realEntity.sender,
                            files: mergedFiles,
                            status: .sent,
                            uploadProgress: 1
                        )

                        guard let newObject = ChatMessageObject.from(entity: mergedEntity) else {
                            promise(.success(false))
                            return
                        }

                        newObject.status = .sent
                        newObject.isRead = true
                        newObject.uploadProgress = 1

                        realm?.add(newObject, update: .all)
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func updateMessageStatus(
        chatId: String,
        status: ChatMessageStatus
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let message = realm?.object(
                            ofType: ChatMessageObject.self,
                            forPrimaryKey: chatId
                        ) {
                            message.status = status
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func markSendingMessagesFailed(roomId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    try realm?.write {
                        let messages = realm?.objects(ChatMessageObject.self)
                            .filter("roomId == %@ AND statusRaw == %@", roomId, ChatMessageStatus.sending.rawValue)
                        messages?.forEach { $0.status = .failed }
                    }
                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func updateUploadProgress(
        chatId: String,
        progress: Float
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let message = realm?.object(
                            ofType: ChatMessageObject.self,
                            forPrimaryKey: chatId
                        ) {
                            message.uploadProgress = progress
                        }
                    }

                    promise(.success(true))
                } catch {
                    print("업로드 진행률 업데이트 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func deleteMessage(chatId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    try realm?.write {
                        if let message = realm?.object(
                            ofType: ChatMessageObject.self,
                            forPrimaryKey: chatId
                        ) {
                            realm?.delete(message)
                        }
                    }
                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchMessage(chatId: String) -> AnyPublisher<ChatEntity?, Never> {
        return Future<ChatEntity?, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    let message = realm?.object(
                        ofType: ChatMessageObject.self,
                        forPrimaryKey: chatId
                    )
                    promise(.success(message?.toEntity()))
                } catch {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchMessages(
        roomId: String,
        cursor: String? = nil,
        limit: Int = 20
    ) -> AnyPublisher<[ChatEntity], Never> {
        return Future<[ChatEntity], Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    var query = realm?.objects(ChatMessageObject.self)
                        .filter("roomId == %@", roomId)

                    // Cursor 기반 필터링
                    if let cursor = cursor,
                       let cursorDate = DateFormatter.iso8601.date(from: cursor) {
                        query = query?.filter("createdAtDate < %@", cursorDate)
                    }

                    // 최신순 정렬 및 limit
                    let results = query?
                        .sorted(byKeyPath: "createdAtDate", ascending: false)
                        .prefix(limit)

                    let entities = results?.map { $0.toEntity() } ?? []

                    promise(.success(entities))
                } catch {
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func observeMessages(roomId: String) -> Results<ChatMessageObject>? {
        guard Thread.isMainThread else {
            print("observeMessages는 메인 스레드에서만 호출 가능")
            return nil
        }

        do {
            let realm = try getRealm()
            return realm.objects(ChatMessageObject.self)
                .filter("roomId == %@", roomId)
                .sorted(byKeyPath: "createdAtDate", ascending: true)
        } catch {
            return nil
        }
    }

    func observeMessagesDescending(roomId: String) -> Results<ChatMessageObject>? {
        guard Thread.isMainThread else {
            return nil
        }

        do {
            let realm = try getRealm()
            return realm.objects(ChatMessageObject.self)
                .filter("roomId == %@", roomId)
                .sorted(byKeyPath: "createdAtDate", ascending: false)
        } catch {
            return nil
        }
    }

    func latestMessageCreatedAt(roomId: String) -> String? {
        guard Thread.isMainThread else {
            print("latestMessageCreatedAt는 메인 스레드에서만 호출 가능")
            return nil
        }

        do {
            let realm = try getRealm()
            let latestMessage = realm.objects(ChatMessageObject.self)
                .filter("roomId == %@", roomId)
                .sorted(byKeyPath: "createdAtDate", ascending: false)
                .first
            return latestMessage?.createdAt
        } catch {
            return nil
        }
    }

    func oldestMessageCreatedAt(roomId: String) -> String? {
        guard Thread.isMainThread else {
            return nil
        }

        do {
            let realm = try getRealm()
            let oldestMessage = realm.objects(ChatMessageObject.self)
                .filter("roomId == %@", roomId)
                .sorted(byKeyPath: "createdAtDate", ascending: true)
                .first
            return oldestMessage?.createdAt
        } catch {
            return nil
        }
    }

    // MARK: - 채팅방 CRUD
    @discardableResult
    func saveRoom(_ entity: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    guard let object = ChatRoomObject.from(entity: entity) else {
                        promise(.success(false))
                        return
                    }

                    try realm?.write {
                        realm?.add(object, update: .all)
                    }

                    promise(.success(true))
                } catch {
                    print("채팅방 저장 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchRooms() -> AnyPublisher<[ChatRoomEntity], Never> {
        return Future<[ChatRoomEntity], Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    let results = realm?.objects(ChatRoomObject.self)
                        .sorted(byKeyPath: "updatedAtDate", ascending: false)

                    let entities = results?.map { $0.toEntity() } ?? []

                    promise(.success(entities))
                } catch {
                    print("채팅방 조회 실패: \(error)")
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func observeRooms() -> Results<ChatRoomObject>? {
        guard Thread.isMainThread else {
            print("observeRooms는 메인 스레드에서만 호출 가능")
            return nil
        }

        do {
            let realm = try getRealm()
            return realm.objects(ChatRoomObject.self)
                .sorted(byKeyPath: "updatedAtDate", ascending: false)
        } catch {
            print("채팅방 관찰 실패: \(error)")
            return nil
        }
    }

    func observeMessagesPublisher(roomId: String, ascending: Bool) -> AnyPublisher<[ChatEntity], Never> {
        Deferred { [weak self] () -> AnyPublisher<[ChatEntity], Never> in
            guard let self = self else {
                return Just([]).eraseToAnyPublisher()
            }

            do {
                let realm = try self.getRealm()
                let results = realm.objects(ChatMessageObject.self)
                    .filter("roomId == %@", roomId)
                    .sorted(byKeyPath: "createdAtDate", ascending: ascending)

                return results.collectionPublisher
                    .map { $0.map { $0.toEntity() } }
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()
            } catch {
                return Just([]).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    func observeRoomsPublisher() -> AnyPublisher<[ChatRoomEntity], Never> {
        Deferred { [weak self] () -> AnyPublisher<[ChatRoomEntity], Never> in
            guard let self = self else {
                return Just([]).eraseToAnyPublisher()
            }

            do {
                let realm = try self.getRealm()
                let results = realm.objects(ChatRoomObject.self)
                    .sorted(byKeyPath: "updatedAtDate", ascending: false)

                return results.collectionPublisher
                    .map { $0.map { $0.toEntity() } }
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()
            } catch {
                return Just([]).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func updateRoomLastMessage(
        roomId: String,
        lastMessage: ChatEntity
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let room = realm?.object(
                            ofType: ChatRoomObject.self,
                            forPrimaryKey: roomId
                        ) {
                            room.lastChatContent = lastMessage.content
                            room.lastChatCreatedAt = lastMessage.createdAt
                            room.updatedAt = lastMessage.createdAt

                            if let updatedAtDate = DateFormatter.iso8601.date(from: lastMessage.createdAt) {
                                room.updatedAtDate = updatedAtDate
                            }
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func incrementUnreadCount(
        roomId: String,
        by count: Int = 1
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let room = realm?.object(
                            ofType: ChatRoomObject.self,
                            forPrimaryKey: roomId
                        ) {
                            room.unreadCount += count
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func markAllMessagesAsRead(roomId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        let messages = realm?.objects(ChatMessageObject.self)
                            .filter("roomId == %@ AND isRead == false", roomId)

                        messages?.forEach { message in
                            message.isRead = true
                        }

                        if let room = realm?.object(
                            ofType: ChatRoomObject.self,
                            forPrimaryKey: roomId
                        ) {
                            room.hasUnread = false
                            room.unreadCount = 0
                        }
                    }

                    promise(.success(true))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func updateRoomFromPush(
        roomId: String,
        lastContent: String,
        lastCreatedAt: String
    ) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            let updatedAtDate = DateFormatter.iso8601.date(from: lastCreatedAt)

            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let room = realm?.object(
                            ofType: ChatRoomObject.self,
                            forPrimaryKey: roomId
                        ) {
                            room.lastChatContent = lastContent
                            room.lastChatCreatedAt = lastCreatedAt
                            room.updatedAt = lastCreatedAt

                            if let date = updatedAtDate {
                                room.updatedAtDate = date
                            }

                            room.hasUnread = true
                            room.unreadCount += 1

                            print("푸시로 방 메타데이터 업데이트: \(roomId), hasUnread: true")
                        } else {
                            print("푸시로 새 방 메타데이터 생성: \(roomId)")

                            let newRoom = ChatRoomObject()
                            newRoom.roomId = roomId
                            newRoom.createdAt = lastCreatedAt
                            newRoom.updatedAt = lastCreatedAt
                            newRoom.lastChatContent = lastContent
                            newRoom.lastChatCreatedAt = lastCreatedAt
                            newRoom.hasUnread = true
                            newRoom.unreadCount = 1

                            if let date = updatedAtDate {
                                newRoom.updatedAtDate = date
                            } else {
                                newRoom.updatedAtDate = Date()
                            }

                            realm?.add(newRoom, update: .all)
                        }
                    }

                    promise(.success(true))
                } catch {
                    print("푸시로 방 메타데이터 업데이트 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func hasAnyUnreadRoom() -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    // hasUnread == true인 방이 하나라도 있는가?
                    let unreadRooms = realm?.objects(ChatRoomObject.self)
                        .filter("hasUnread == true")

                    let hasUnread = !(unreadRooms?.isEmpty ?? true)

                    promise(.success(hasUnread))
                } catch {
                    print("안 읽은 방 체크 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func deleteAllChatData() -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        realm?.deleteAll()
                    }

                    promise(.success(true))
                } catch {
                    print("채팅 데이터 삭제 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
