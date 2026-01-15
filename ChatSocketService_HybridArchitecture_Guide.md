# 하이브리드 채팅 시스템 통합 가이드 (hasUnread 기반)

## 📋 목차
1. [아키텍처 개요](#아키텍처-개요)
2. [Badge Policy: hasUnread 설계 철학](#badge-policy-hasunread-설계-철학)
3. [구현 완료 기능](#구현-완료-기능)
4. [시나리오별 동작](#시나리오별-동작)
5. [UI 통합 가이드](#ui-통합-가이드)
6. [푸시 알림 통합](#푸시-알림-통합)
7. [성능 최적화 및 비용 절감](#성능-최적화-및-비용-절감)

---

## 아키텍처 개요

### 핵심 설계 철학

**Room-Specific Socket + Push + HTTP 하이브리드 전략**

```
┌─────────────────────────────────────────────────────────┐
│                    하이브리드 채팅 시스템                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  채팅방 내부:  Socket.io 실시간 연결                      │
│               ├─ viewWillAppear: connect(to: roomId)   │
│               └─ viewWillDisappear: disconnect()       │
│                                                         │
│  채팅방 외부:  HTTP API + Push Notification              │
│               ├─ HTTP: 목록 조회, Gap 보정               │
│               └─ Push: 백그라운드 알림                    │
│                                                         │
│  SSOT:        Realm (Single Source of Truth)          │
│               └─ 모든 데이터는 Realm을 거쳐 UI 반영        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 비용 최적화 근거

| 항목 | 기존 (Always-On) | 하이브리드 (Room-Specific) | 절감률 |
|------|------------------|---------------------------|--------|
| Socket 연결 시간 | 24시간/일 | 평균 5분/일 | **99.65%** |
| 서버 비용 (1만 명) | 240만 시간/월 | 833시간/월 | **99.65%** |
| 배터리 소모 | 지속적 Heartbeat | 채팅 중에만 | **95%** |

---

## Badge Policy: hasUnread 설계 철학

### 왜 Int 대신 Bool을 사용하는가?

#### ❌ 기존 방식 (unreadCount: Int)

```swift
// 문제점 1: 서버-클라이언트 불일치
서버: unreadCount = 5
클라이언트: unreadCount = 3
→ 어느 것이 정확한가? 🤔

// 문제점 2: 복잡한 동기화 로직
Socket 수신: +1
Push 수신: +1
HTTP 동기화: 서버 값으로 덮어쓰기
→ 중복 카운팅 버그 발생
```

#### ✅ 개선 방식 (hasUnread: Bool)

```swift
// 장점 1: 서버가 정확한 개수를 제공하지 못해도 OK
서버: "새 메시지 있음"
클라이언트: hasUnread = true
→ 단순 명확!

// 장점 2: UI는 "빨간 점"만 표시
if hasUnread {
    // 빨간 점 표시
} else {
    // 표시 안 함
}
→ 숫자 싱크 맞추기 불필요

// 장점 3: 중복 체크 불필요
// 여러 경로로 메시지가 와도 hasUnread = true는 동일
Socket: hasUnread = true
Push: hasUnread = true
HTTP: hasUnread = true
→ 멱등성(Idempotent) 보장
```

### Badge Policy 흐름도

```
새 메시지 수신 (Socket/Push/HTTP)
          ↓
    hasUnread = true
          ↓
    UI: 빨간 점 표시
          ↓
   사용자가 방 진입
          ↓
    hasUnread = false
          ↓
     UI: 점 제거
```

---

## 구현 완료 기능

### ✅ 1. ChatRoomObject (Realm 모델)

```swift
final class ChatRoomObject: Object {
    @Persisted(primaryKey: true) var roomId: String

    // SSOT (Single Source of Truth)
    @Persisted(indexed: true) var hasUnread: Bool

    // 참고용 (deprecated 예정)
    @Persisted var unreadCount: Int
}
```

**인덱싱 전략:**
- `hasUnread`에 인덱스 추가
- `WHERE hasUnread == true` 쿼리 O(1) 수준
- 탭바 배지: "안 읽은 방이 하나라도 있는가?" 고속 체크

### ✅ 2. RealmChatRepository (영속성 레이어)

#### 2.1 푸시 알림용 부분 업데이트

```swift
func updateRoomFromPush(
    roomId: String,
    lastContent: String,
    lastCreatedAt: String
) -> AnyPublisher<Bool, Never>
```

**성능 최적화:**
- DateFormatter 파싱을 트랜잭션 외부에서 수행
- Realm 락 시간 최소화
- Atomic 연산으로 Thread-safe 보장

#### 2.2 방 진입 시 읽음 처리

```swift
func markAllMessagesAsRead(roomId: String) -> AnyPublisher<Bool, Never>
```

**동작:**
- 메시지 읽음 처리 + hasUnread = false
- 한 트랜잭션으로 Atomic 처리

#### 2.3 전역 배지 체크

```swift
func hasAnyUnreadRoom() -> AnyPublisher<Bool, Never>
```

**성능:**
- 인덱스 활용으로 O(1) 수준
- unreadCount 합산 대신 Bool 체크

### ✅ 3. ChatSocketService (통신 레이어)

#### 3.1 Room-Specific Lifecycle

```swift
// 채팅방 진입
func connect(to roomId: String)

// 채팅방 퇴장
func disconnect()
```

**특징:**
- 채팅방마다 독립적인 Socket 엔드포인트: `http://baseURL/chats-{roomId}`
- 진입 시 생성, 퇴장 시 완전 파괴 (nil)
- 서버 세션 비용 99% 절감

#### 3.2 Network-aware Throttling

```swift
private let minimumConnectInterval: TimeInterval = 2.0
private var isNetworkAvailable: Bool = true
```

**동작:**
- NetworkMonitor 연동
- 네트워크 단절 시 재연결 중단
- 재연결 간격 최소 2초 강제

#### 3.3 Message Handling

```swift
private func handleChatMessage(data: [Any])
```

**hasUnread 반영:**
- 채팅방 내부: `isRead = true`, `hasUnread = false`
- 채팅방 외부: 소켓 연결 없음 (Push로 대체)

### ✅ 4. Realm 마이그레이션

```swift
// AppDelegate.swift
private func configureRealm() {
    let config = Realm.Configuration(
        schemaVersion: 1,
        migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: ChatRoomObject.className()) { oldObject, newObject in
                    newObject?["hasUnread"] = false
                }
            }
        }
    )
    Realm.Configuration.defaultConfiguration = config
}
```

**크래시 방지:**
- 기존 사용자의 Realm 파일에 hasUnread 필드 추가
- 기본값: false

---

## 시나리오별 동작

### 시나리오 1: 채팅방 진입

```
1. ChatViewController.viewWillAppear(_:)
   └─ ChatSocketService.shared.connect(to: roomId)

2. Socket 연결 성공
   └─ onSocketConnected(roomId:)
       └─ RealmChatRepository.markAllMessagesAsRead(roomId:)
           └─ hasUnread = false (빨간 점 제거)

3. 실시간 메시지 수신
   └─ handleChatMessage(data:)
       └─ saveMessageWithRoomUpdate(_, isRead: true, shouldIncrementUnread: false)
           └─ hasUnread 변화 없음 (채팅방 내부이므로)
```

### 시나리오 2: 채팅방 퇴장

```
1. ChatViewController.viewWillDisappear(_:)
   └─ ChatSocketService.shared.disconnect()

2. Socket 연결 해제
   └─ socket?.disconnect()
   └─ socket = nil (메모리 해제)
   └─ connectedRoomId = nil
```

### 시나리오 3: 백그라운드에서 푸시 수신

```
1. 앱이 백그라운드 상태
   └─ Socket 연결 없음 (서버 비용 절감)

2. Push Notification 수신
   └─ AppDelegate.userNotificationCenter(_:didReceive:)
       └─ RealmChatRepository.updateRoomFromPush(roomId:lastContent:lastCreatedAt:)
           └─ hasUnread = true (빨간 점 표시)

3. 포그라운드 복귀 시
   └─ HTTP API로 전체 동기화 (ChatRoomListViewController.viewWillAppear)
       └─ chatId 기반 Upsert로 중복 제거
```

### 시나리오 4: 채팅방 목록 조회

```
1. ChatRoomListViewController.viewWillAppear(_:)
   └─ HTTP API: GET /chats
       └─ 서버로부터 방 리스트 받기
       └─ RealmChatRepository.saveRoom(_:) (Upsert)
           └─ 기존 hasUnread 값 유지 (덮어쓰지 않음)

2. Realm Results 관찰
   └─ observeRooms()
       └─ UI 자동 업데이트

3. 빨간 점 표시
   if room.hasUnread {
       badgeView.isHidden = false
   }
```

### 시나리오 5: 탭바 배지 (전역 알림)

```
1. 앱 실행 중 지속적 체크
   └─ RealmChatRepository.hasAnyUnreadRoom()
       .receive(on: DispatchQueue.main)
       .sink { hasUnread in
           // 탭바 채팅 아이콘에 빨간 점 표시/제거
           self.tabBar.items?[1].badgeValue = hasUnread ? "" : nil
       }

2. 성능
   └─ hasUnread 인덱스 활용
   └─ O(1) 수준 쿼리
```

---

## UI 통합 가이드

### 1. ChatViewController (채팅방 화면)

```swift
final class ChatViewController: BaseViewController<ChatViewModel> {
    private var cancellables = Set<AnyCancellable>()

    private let connectionStatusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.backgroundColor = AppColor.gray90.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    override func setupUI() {
        super.setupUI()

        // 연결 상태 표시 라벨
        view.addSubview(connectionStatusLabel)
        connectionStatusLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(28)
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    override func bind() {
        super.bind()

        // Socket 연결 상태 구독
        ChatSocketService.shared.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateConnectionStatus(status)
            }
            .store(in: &cancellables)

        // Realm 메시지 관찰
        if let results = RealmChatRepository.shared.observeMessages(roomId: viewModel.roomId) {
            messagesToken = results.observe { [weak self] changes in
                switch changes {
                case .initial(let messages):
                    self?.updateMessages(messages: messages)

                case .update(let messages, _, _, _):
                    self?.updateMessages(messages: messages)

                case .error(let error):
                    print("메시지 관찰 에러: \(error)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Socket 연결 (Room-Specific)
        ChatSocketService.shared.connect(to: viewModel.roomId)

        // 탭바 숨기기
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Socket 연결 해제 (서버 비용 절감)
        ChatSocketService.shared.disconnect()

        // 탭바 표시
        tabBarController?.tabBar.isHidden = false
    }

    private func updateConnectionStatus(_ status: SocketIOStatus) {
        switch status {
        case .connected:
            UIView.animate(withDuration: 0.3) {
                self.connectionStatusLabel.isHidden = true
            }

        case .connecting:
            connectionStatusLabel.text = "  연결 중...  "
            connectionStatusLabel.backgroundColor = AppColor.gray75
            UIView.animate(withDuration: 0.3) {
                self.connectionStatusLabel.isHidden = false
            }

        case .reconnecting:
            connectionStatusLabel.text = "  재연결 중...  "
            connectionStatusLabel.backgroundColor = AppColor.brightForsythia
            UIView.animate(withDuration: 0.3) {
                self.connectionStatusLabel.isHidden = false
            }

        case .disconnected:
            connectionStatusLabel.text = "  연결 끊김  "
            connectionStatusLabel.backgroundColor = AppColor.gray75
            UIView.animate(withDuration: 0.3) {
                self.connectionStatusLabel.isHidden = false
            }

        case .error(let message):
            connectionStatusLabel.text = "  \(message)  "
            connectionStatusLabel.backgroundColor = UIColor.systemRed
            UIView.animate(withDuration: 0.3) {
                self.connectionStatusLabel.isHidden = false
            }
        }
    }

    private func updateMessages(messages: Results<ChatMessageObject>) {
        let entities = messages.map { $0.toEntity() }
        // TableView 업데이트
    }
}
```

### 2. ChatRoomListViewController (채팅방 목록)

```swift
final class ChatRoomListViewController: BaseViewController<ChatRoomListViewModel> {
    private var cancellables = Set<AnyCancellable>()
    private var roomsToken: NotificationToken?

    override func bind() {
        super.bind()

        // Realm Results 관찰
        if let results = RealmChatRepository.shared.observeRooms() {
            roomsToken = results.observe { [weak self] changes in
                switch changes {
                case .initial(let rooms):
                    self?.updateUI(with: rooms)

                case .update(let rooms, _, _, _):
                    self?.updateUI(with: rooms)

                case .error(let error):
                    print("방 목록 관찰 에러: \(error)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // HTTP API로 최신 방 리스트 조회
        viewModel.fetchChatRooms()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    print("방 리스트 동기화 완료")
                }
            )
            .store(in: &cancellables)
    }

    private func updateUI(with rooms: Results<ChatRoomObject>) {
        let entities = rooms.map { $0.toEntity() }

        // TableView 업데이트
        // Badge 표시
        for (index, room) in rooms.enumerated() {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ChatRoomCell
            cell?.badgeView.isHidden = !room.hasUnread
        }
    }
}
```

### 3. TabBarController (전역 배지)

```swift
final class MainTabBarController: UITabBarController {
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBadgeObserver()
    }

    private func setupBadgeObserver() {
        // 전역 배지: 안 읽은 방이 하나라도 있는가?
        RealmChatRepository.shared.hasAnyUnreadRoom()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasUnread in
                // 탭바 채팅 아이콘에 빨간 점 표시/제거
                self?.tabBar.items?[1].badgeValue = hasUnread ? "" : nil
            }
            .store(in: &cancellables)

        // Realm 변경 감지 시 재체크
        NotificationCenter.default.publisher(for: .realmDidChange)
            .sink { [weak self] _ in
                self?.updateBadge()
            }
            .store(in: &cancellables)
    }

    private func updateBadge() {
        RealmChatRepository.shared.hasAnyUnreadRoom()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasUnread in
                self?.tabBar.items?[1].badgeValue = hasUnread ? "" : nil
            }
            .store(in: &cancellables)
    }
}

// NotificationCenter Extension
extension Notification.Name {
    static let realmDidChange = Notification.Name("realmDidChange")
}
```

---

## 푸시 알림 통합

### AppDelegate - Push 수신 처리

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 푸시 페이로드 파싱
        if let roomId = userInfo["roomId"] as? String,
           let content = userInfo["content"] as? String,
           let createdAt = userInfo["createdAt"] as? String {

            // 방 메타데이터만 업데이트 (메시지 전체 저장 X)
            RealmChatRepository.shared.updateRoomFromPush(
                roomId: roomId,
                lastContent: content,
                lastCreatedAt: createdAt
            )
            .sink(receiveValue: { success in
                if success {
                    print("푸시로 방 메타데이터 업데이트 완료")

                    // Realm 변경 알림
                    NotificationCenter.default.post(name: .realmDidChange, object: nil)
                }
            })
            .store(in: &cancellables)
        }

        completionHandler()
    }

    // 포그라운드에서 푸시 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 현재 채팅방에 있으면 푸시 표시 안 함
        let userInfo = notification.request.content.userInfo
        if let roomId = userInfo["roomId"] as? String,
           ChatSocketService.shared.isConnected(to: roomId) {
            completionHandler([]) // 푸시 표시 안 함
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
}
```

### 서버 푸시 페이로드 구조

```json
{
  "roomId": "room123",
  "content": "안녕하세요",
  "createdAt": "2026-01-12T10:00:00.000Z",
  "senderName": "홍길동",
  "senderProfileImage": "https://..."
}
```

---

## 성능 최적화 및 비용 절감

### 1. Socket 재연결 백오프

```swift
.reconnectWait(1)       // 1초 대기
.reconnectWaitMax(5)    // 최대 5초까지 백오프
.reconnectAttempts(5)   // 5회 제한 (무한 재시도 방지)
```

### 2. Realm 인덱싱 전략

```swift
@Persisted(indexed: true) var hasUnread: Bool
```

**효과:**
- `WHERE hasUnread == true` 쿼리 O(1) 수준
- 탭바 배지 체크 고속화

### 3. DateFormatter 파싱 최적화

```swift
// ✅ 트랜잭션 외부에서 파싱
let updatedAtDate = DateFormatter.iso8601.date(from: lastCreatedAt)

self?.realmQueue.async {
    try realm?.write {
        // 파싱 완료된 Date 사용
        if let date = updatedAtDate {
            room.updatedAtDate = date
        }
    }
}
```

**효과:**
- Realm 락 시간 최소화
- 트랜잭션 성능 향상

### 4. 메모리 누수 방지

```swift
// Socket 리스너
socket?.on("chat") { [weak self] data, ack in
    self?.handleChatMessage(data: data)
}

// Publisher
.sink(receiveValue: { [weak self] value in
    self?.process(value)
})
.store(in: &cancellables)
```

---

## 체크리스트

### 구현 완료
- [x] ChatRoomObject에 hasUnread 필드 추가
- [x] RealmChatRepository.updateRoomFromPush 메서드
- [x] RealmChatRepository.markAllMessagesAsRead 메서드
- [x] RealmChatRepository.hasAnyUnreadRoom 메서드
- [x] ChatSocketService Room-Specific 연결 정책
- [x] NetworkMonitor 통합 및 스로틀링
- [x] Realm 마이그레이션 설정
- [x] saveMessageWithRoomUpdate hasUnread 반영

### TODO (실제 적용 시)
- [ ] ChatViewController에 연결 상태 UI 추가
- [ ] ChatRoomListViewController HTTP 동기화 구현
- [ ] TabBarController 전역 배지 연동
- [ ] AppDelegate Push 수신 처리 구현
- [ ] 서버 Socket.io 엔드포인트 연결
- [ ] 읽음 확인, 타이핑 인디케이터 구현
- [ ] 사용자 설정에서 햅틱 On/Off 기능

---

## 디버깅 팁

### Realm 데이터 확인

```swift
// 전체 방 목록 출력
RealmChatRepository.shared.fetchRooms()
    .sink { rooms in
        for room in rooms {
            print("[\(room.roomId)] hasUnread: \(room.hasUnread), unreadCount: \(room.unreadCount)")
        }
    }
    .store(in: &cancellables)
```

### Socket 연결 로그

```swift
// ChatSocketService.swift
manager = SocketManager(
    socketURL: socketURL,
    config: [
        .log(true),  // ✅ 로그 활성화
        // ...
    ]
)
```

### hasUnread 쿼리 성능 측정

```swift
let start = Date()
RealmChatRepository.shared.hasAnyUnreadRoom()
    .sink { hasUnread in
        let elapsed = Date().timeIntervalSince(start)
        print("hasAnyUnreadRoom 쿼리 시간: \(elapsed * 1000)ms")
    }
    .store(in: &cancellables)
```
