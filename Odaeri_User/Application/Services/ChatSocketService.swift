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
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    /// 재연결 스로틀링
    private var lastConnectAttempt: Date?
    private let minimumConnectInterval: TimeInterval = 2.0
    private var isNetworkAvailable: Bool = true

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
        let baseURLString = APIEnvironment.current.baseURL.absoluteString

        guard let socketURL = URL(string: "\(baseURLString)/chats-\(roomId)") else {
            print("Socket URL 생성 실패: \(baseURLString)/chats-\(roomId)")
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

        print("Socket 생성: \(socketURL.absoluteString)")

        manager = SocketManager(
            socketURL: socketURL,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(1),
                .reconnectWaitMax(5),
                .extraHeaders(["Authorization": "\(accessToken)"])
            ]
        )

        socket = manager?.defaultSocket
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
            realmRepo.updateMessageStatus(chatId: tempId, status: .error)
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
            print("Socket 연결됨")
            self.connectionStatus.send(.connected)
            self.onSocketConnected(roomId: roomId)
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket 연결 해제됨: \(data)")
            self?.connectionStatus.send(.disconnected)
        }

        socket?.on(clientEvent: .reconnect) { [weak self] data, ack in
            print("Socket 재연결됨")
            self?.connectionStatus.send(.connected)
            self?.onSocketConnected(roomId: roomId)
        }

        socket?.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            if let attemptNumber = data.first as? Int {
                print("재연결 시도 #\(attemptNumber)")
            }
            self?.connectionStatus.send(.reconnecting)
        }

        socket?.on(clientEvent: .error) { [weak self] data, ack in
            guard let self = self else { return }
            print("Socket 에러: \(data)")

            if let errorDict = data.first as? [String: Any],
               let type = errorDict["type"] as? String,
               type == "UnauthorizedError" {
                print("토큰 만료 감지: Socket 재생성 필요")
                self.connectionStatus.send(.error("인증 만료"))
            } else {
                self.connectionStatus.send(.error("연결 오류"))
            }
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
        guard let dict = data.first as? [String: Any],
              let response = try? parseChatResponse(from: dict) else {
            print("메시지 파싱 실패: \(data)")
            return
        }

        let entity = ChatEntity(from: response)

        guard entity.roomId == connectedRoomId else {
            print("다른 방의 메시지 수신 무시: \(entity.roomId)")
            return
        }
        print("메시지 수신: \(entity.chatId)")

        provideHapticFeedback()

        realmRepo.saveMessageWithRoomUpdate(
            entity,
            isRead: true,
            shouldIncrementUnread: false
        )
        .sink(receiveValue: { success in
            if success {
                print("메시지 저장 + 방 업데이트 완료")
            } else {
                print("메시지 처리 실패")
            }
        })
        .store(in: &cancellables)
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
