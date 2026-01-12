//
//  ChatSocketService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import Foundation
import Combine
import SocketIO
import UIKit

enum SocketIOStatus {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var displayMessage: String {
        switch self {
        case .disconnected:
            return "연결 끊김"
        case .connecting:
            return "연결 중..."
        case .connected:
            return "연결됨"
        case .reconnecting:
            return "재연결 중..."
        case .error(let message):
            return "오류: \(message)"
        }
    }
}

final class ChatSocketService {
    static let shared = ChatSocketService()

    private let realmRepo = RealmChatRepository.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var connectedRoomId: String?
    let connectionStatus = CurrentValueSubject<SocketIOStatus, Never>(.disconnected)
    let messagesPublisher = PassthroughSubject<ChatEntity, Never>()
    let reconnectionPublisher = PassthroughSubject<String, Never>()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    /// 재연결 스로틀링
    private var lastConnectAttempt: Date?
    private let minimumConnectInterval: TimeInterval = 2.0
    private var isNetworkAvailable: Bool = true

    /// 최초 연결 여부 (방별로 추적)
    private var isFirstConnection: [String: Bool] = [:]

    private init() {
        hapticGenerator.prepare()
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                self.isNetworkAvailable = isConnected

                if !isConnected {
                    print("네트워크 단절 감지")
                    self.connectionStatus.send(.error("네트워크 연결 없음"))
                } else {
                    print("네트워크 복구 감지")

                    // 채팅방 내부에 있었다면 재연결
                    if let roomId = self.connectedRoomId,
                       self.socket?.status != .connected {
                        print("네트워크 복구: \(roomId) 재연결 시도")
                        self.connect(to: roomId)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func setupSocket(for roomId: String) {
        let baseURL = APIEnvironment.current.baseURL
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            print("Socket URL 생성 실패: \(baseURL.absoluteString)")
            connectionStatus.send(.error("잘못된 서버 주소"))
            return
        }
        components.path = ""
        components.query = nil
        components.fragment = nil

        guard let socketURL = components.url else {
            print("Socket URL 생성 실패: \(baseURL.absoluteString)")
            connectionStatus.send(.error("잘못된 서버 주소"))
            return
        }

        guard let accessToken = TokenManager.shared.accessToken else {
            print("토큰 없음: Socket 연결 불가")
            connectionStatus.send(.error("로그인 필요"))
            return
        }

        // 소켓 재생성 (기존 연결이 있다면 해제)
        if let existingSocket = socket {
            existingSocket.disconnect()
            existingSocket.removeAllHandlers()
        }

        let namespace = "/chats-\(roomId)"
        print("Socket 생성: \(socketURL.absoluteString)\(namespace)")

        manager = SocketManager(
            socketURL: socketURL,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(1),
                .reconnectWaitMax(5),
                .extraHeaders([
                    "Authorization": "\(accessToken)",
                    "SeSACKey": APIEnvironment.current.apiKey
                ])
            ]
        )

        socket = manager?.socket(forNamespace: namespace)
        setupSocketListeners(for: roomId)
    }

    private func recreateSocketWithNewToken() {
        guard let roomId = connectedRoomId else {
            print("재연결할 방이 없음")
            return
        }

        print("토큰 갱신: Socket 재생성")

        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil

        setupSocket(for: roomId)
        connect(to: roomId)
    }

    func connect(to roomId: String) {
        guard isNetworkAvailable else {
            print("네트워크 없음: Socket 연결 중단")
            connectionStatus.send(.error("네트워크 연결 없음"))
            return
        }

        if let lastAttempt = lastConnectAttempt {
            let elapsed = Date().timeIntervalSince(lastAttempt)
            if elapsed < minimumConnectInterval {
                print("재연결 시도 너무 빠름. \(minimumConnectInterval - elapsed)초 후 재시도")

                DispatchQueue.main.asyncAfter(deadline: .now() + (minimumConnectInterval - elapsed)) { [weak self] in
                    self?.connect(to: roomId)
                }
                return
            }
        }

        if connectedRoomId == roomId, socket?.status == .connected {
            print("이미 \(roomId)에 연결되어 있음")
            return
        }

        if let previousRoomId = connectedRoomId, previousRoomId != roomId {
            print("기존 방 \(previousRoomId) 연결 해제 후 \(roomId) 연결")
            disconnect()
        }

        lastConnectAttempt = Date()
        connectedRoomId = roomId

        setupSocket(for: roomId)
        connectionStatus.send(.connecting)
        socket?.connect()

        print("채팅방 \(roomId)에 Socket 연결 시도")
    }

    func disconnect() {
        guard let roomId = connectedRoomId else {
            print("연결된 방이 없음: 해제 작업 스킵")
            return
        }

        print("채팅방 \(roomId) Socket 연결 해제")

        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil

        // 방을 완전히 나가므로 최초 연결 플래그 초기화
        isFirstConnection.removeValue(forKey: roomId)
        connectedRoomId = nil
        connectionStatus.send(.disconnected)
    }

    func sendMessage(
        roomId: String,
        content: String,
        tempId: String,
        files: [String] = []
    ) {
        guard socket?.status == .connected else {
            print("Socket 연결 안 됨: 메시지 전송 실패")
            realmRepo.updateMessageStatus(chatId: tempId, status: .failed)
            return
        }

        let payload: [String: Any] = [
            "roomId": roomId,
            "content": content,
            "files": files,
            "tempId": tempId
        ]

        socket?.emit("chat", payload)
        print("메시지 전송: \(tempId)")
    }

    private func setupSocketListeners(for roomId: String) {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            guard let self = self else { return }
            print("✅ Socket 연결 성공! roomId: \(roomId)")
            print("✅ Socket 상태: \(self.socket?.status.description ?? "unknown")")
            self.connectionStatus.send(.connected)
            self.onSocketConnected(roomId: roomId)

            // 최초 연결인지 확인
            if self.isFirstConnection[roomId] == true {
                // 최초 연결이 아니면 (재연결) 동기화 이벤트 발행
                print("재연결 감지 (.connect): \(roomId) 동기화 필요")
                self.reconnectionPublisher.send(roomId)
            } else {
                // 최초 연결
                print("최초 연결: \(roomId) 동기화 스킵 (viewDidLoad에서 처리)")
                self.isFirstConnection[roomId] = true
            }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket 연결 해제됨: \(data)")
            self?.connectionStatus.send(.disconnected)
        }

        socket?.on(clientEvent: .reconnect) { [weak self] data, ack in
            guard let self = self else { return }
            print("Socket 재연결됨: \(roomId)")
            self.connectionStatus.send(.connected)
            self.onSocketConnected(roomId: roomId)

            // 재연결 성공 시 동기화 이벤트 발행
            self.reconnectionPublisher.send(roomId)
        }

        socket?.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            if let attemptNumber = data.first as? Int {
                print("재연결 시도 #\(attemptNumber)")
            }
            self?.connectionStatus.send(.reconnecting)
        }

        socket?.on(clientEvent: .error) { [weak self] data, ack in
            guard let self = self else { return }
            self.handleSocketError(data)
        }

        socket?.on("chat") { [weak self] data, ack in
            guard let self = self else { return }
            self.handleChatMessage(data: data)
        }

        socket?.on("read") { [weak self] data, ack in
            self?.handleReadReceipt(data: data)
        }

        socket?.on("typing") { [weak self] data, ack in
            self?.handleTypingIndicator(data: data)
        }
    }

    private func onSocketConnected(roomId: String) {
        print("Socket 연결 완료: \(roomId)")

        // Realm 읽음 처리
        realmRepo.markAllMessagesAsRead(roomId: roomId)
            .sink(receiveValue: { success in
                if success {
                    print("채팅방 진입: 모든 메시지 읽음 처리 완료")
                }
            })
            .store(in: &cancellables)
    }

    private func handleChatMessage(data: [Any]) {
        print("🔔 Socket 'chat' 이벤트 수신!")
        print("🔔 data: \(data)")

        guard let dict = data.first as? [String: Any],
              let response = try? parseChatResponse(from: dict) else {
            print("❌ 메시지 파싱 실패: \(data)")
            return
        }

        let entity = ChatEntity(from: response)
        print("🔔 파싱된 메시지: chatId=\(entity.chatId), roomId=\(entity.roomId), sender=\(entity.sender.userId)")

        guard entity.roomId == connectedRoomId else {
            print("⚠️ 다른 방의 메시지 수신 무시: \(entity.roomId) (현재: \(connectedRoomId ?? "nil"))")
            return
        }
        print("✅ 메시지 수신 확인: \(entity.chatId)")

        provideHapticFeedback()

        realmRepo.saveMessageWithRoomUpdate(
            entity,
            isRead: true,
            shouldIncrementUnread: false
        )
        .sink { success in
            if success {
                print("소켓 수신 메시지 저장 완료: \(entity.chatId)")
            } else {
                print("소켓 수신 메시지 저장 실패: \(entity.chatId)")
            }
        }
        .store(in: &cancellables)

        messagesPublisher.send(entity)
    }

    private func handleSocketError(_ data: [Any]) {
        let message = parseSocketErrorMessage(from: data)
        print("Socket 에러: \(message ?? "unknown")")

        if let message = message, isAuthenticationError(message) {
            connectionStatus.send(.error("인증 오류"))
            NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
            return
        }

        if let message = message, isNamespaceError(message) {
            connectionStatus.send(.error("네임스페이스 오류"))
            return
        }

        if let message = message, isChatRoomError(message) {
            connectionStatus.send(.error("채팅방 오류"))
            return
        }

        if let message = message, isServiceKeyError(message) {
            connectionStatus.send(.error("서비스 키 오류"))
            return
        }

        connectionStatus.send(.error("연결 오류"))
    }

    private func parseSocketErrorMessage(from data: [Any]) -> String? {
        if let dict = data.first as? [String: Any] {
            if let message = dict["message"] as? String {
                return message
            }
            if let description = dict["error"] as? String {
                return description
            }
        }

        if let message = data.first as? String {
            return message
        }

        return nil
    }

    private func isAuthenticationError(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return lowercased.contains("access token") ||
            lowercased.contains("accesstoken") ||
            lowercased.contains("user_id") ||
            lowercased.contains("unauthorized")
    }

    private func isServiceKeyError(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return lowercased.contains("sesac") || lowercased.contains("productid")
    }

    private func isNamespaceError(_ message: String) -> Bool {
        return message.localizedCaseInsensitiveContains("invalid namespace")
    }

    private func isChatRoomError(_ message: String) -> Bool {
        return message.contains("채팅방을 찾을 수 없습니다") ||
            message.contains("채팅방 참여자가 아닙니다")
    }
    
    private func handleReadReceipt(data: [Any]) {
        guard let dict = data.first as? [String: Any],
              let chatId = dict["chatId"] as? String else {
            print("읽음 확인 파싱 실패: \(data)")
            return
        }

        print("읽음 확인 수신: \(chatId)")

        // TODO: Realm에 읽음 상태 업데이트
        // realmRepo.updateReadStatus(chatId: chatId, isRead: true)
    }

    private func handleTypingIndicator(data: [Any]) {
        guard let dict = data.first as? [String: Any],
              let userId = dict["userId"] as? String,
              let isTyping = dict["isTyping"] as? Bool else {
            print("타이핑 인디케이터 파싱 실패: \(data)")
            return
        }

        print("타이핑 중: \(userId) - \(isTyping)")

        // TODO: NotificationCenter 또는 Publisher로 UI에 전달
        // NotificationCenter.default.post(name: .chatTypingIndicator, object: nil, userInfo: ["userId": userId, "isTyping": isTyping])
    }

    private func provideHapticFeedback() {
        DispatchQueue.main.async { [weak self] in
            self?.hapticGenerator.impactOccurred()
        }
    }

    // MARK: - Helper
    private func parseChatResponse(from dict: [String: Any]) throws -> ChatResponse {
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        let decoder = JSONDecoder()
        return try decoder.decode(ChatResponse.self, from: jsonData)
    }
}
