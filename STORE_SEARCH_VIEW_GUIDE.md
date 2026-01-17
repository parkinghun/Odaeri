# 가게 검색 뷰 구현 가이드

## 개요
HomeViewController, CommunityPostViewController 등 여러 곳에서 공통으로 사용할 수 있는 **재사용 가능한 가게 검색 뷰**입니다.

진입 목적(`StoreSearchViewType`)에 따라 초기 화면 상태와 보여주는 데이터가 달라집니다.

---

## 주요 특징

### 1. 타입별 다른 동작
- **`.home`**: 일반적인 검색 모드 (초기 상태에서 안내 문구만 표시)
- **`.community`**: 글 작성을 위한 모드 (최근 결제/방문 내역 우선 노출)

### 2. State Machine 기반 UI 제어
검색어 유무와 타입에 따라 자동으로 UI 상태가 전환됩니다.

### 3. Clean Architecture + MVVM-C
- Coordinator 없이도 재사용 가능
- Delegate 패턴으로 가게 선택 이벤트 전달

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│            StoreSearchViewController                    │
│  - UISearchBar (검색창)                                  │
│  - UITableView (검색 결과/최근 내역)                     │
│  - UILabel (상태 메시지)                                 │
│  - StoreSearchDelegate (가게 선택 콜백)                  │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│            StoreSearchViewModel                          │
│  - StoreRepository (검색)                                │
│  - OrderRepository (최근 주문 내역)                      │
│  - State Machine (상태 관리)                             │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼──────┐    ┌────────▼─────────┐
│StoreRepository│    │OrderRepository   │
│- searchStores│    │- getOrderList    │
└──────────────┘    └──────────────────┘
```

---

## 컴포넌트

### 1. StoreSearchViewType (Enum)

**위치**: `Odaeri_User/Presentation/Common/Models/StoreSearchViewType.swift`

```swift
enum StoreSearchViewType {
    case home
    case community
}
```

**프로퍼티**:
- `navigationTitle`: 네비게이션 타이틀
- `searchPlaceholder`: 검색창 플레이스홀더
- `emptyStateMessage`: 초기 상태 메시지
- `showsRecentStores`: 최근 가게 표시 여부

### 2. StoreSearchViewState (Enum)

**위치**: `StoreSearchViewModel.swift` 내부

```swift
enum StoreSearchViewState {
    case initial                    // 초기 상태
    case searching                  // 검색 중
    case results([StoreEntity])     // 검색 결과
    case empty(String)              // 검색 결과 없음
    case recentStores([StoreEntity]) // 최근 방문 가게
}
```

**프로퍼티**:
- `shouldShowTableView`: 테이블뷰 표시 여부
- `shouldShowEmptyLabel`: 빈 상태 라벨 표시 여부
- `emptyMessage`: 빈 상태 메시지
- `sectionTitle`: 테이블뷰 섹션 헤더

### 3. StoreSearchDelegate (Protocol)

**위치**: `Odaeri_User/Presentation/Common/Protocols/StoreSearchDelegate.swift`

```swift
protocol StoreSearchDelegate: AnyObject {
    func didSelectStore(_ store: StoreEntity)
}
```

가게 선택 시 이벤트를 전달받기 위한 프로토콜입니다.

### 4. StoreSearchViewModel

**위치**: `Odaeri_User/Presentation/Common/ViewModels/StoreSearchViewModel.swift`

**Input**:
- `viewDidLoad`: 화면 로드
- `searchTextChanged`: 검색어 변경 (300ms debounce)

**Output**:
- `viewState`: UI 상태
- `stores`: 가게 리스트
- `isLoading`: 로딩 상태
- `error`: 에러 메시지

**주요 로직**:
- `.home`: 초기 상태 표시
- `.community`: `OrderRepository.getOrderList()` 호출 → 최근 주문한 가게 추출
- 검색 시: `StoreRepository.searchStores()` 호출

### 5. StoreSearchViewController

**위치**: `Odaeri_User/Presentation/Common/Views/StoreSearchViewController.swift`

**UI 컴포넌트**:
- `UISearchBar`: 검색창
- `UITableView`: 검색 결과/최근 내역
- `UILabel`: 상태 메시지 (중앙 정렬)

**Delegate**:
- `StoreSearchDelegate`: 가게 선택 콜백

### 6. StoreSearchCell

**위치**: `Odaeri_User/Presentation/Common/Views/StoreSearchCell.swift`

**표시 정보**:
- 가게 이름 (bold)
- 카테고리 (gray)
- 주소 (small gray)
- Chevron 아이콘

---

## State Machine 동작

### A. 검색어가 없을 때 (초기 상태)

#### Home Type
```
┌────────────────────────────────┐
│     [검색창]                    │
├────────────────────────────────┤
│                                │
│   원하시는 가게를 검색해보세요.  │
│                                │
└────────────────────────────────┘
```
- **TableView**: 숨김
- **Label**: 표시 ("원하시는 가게를 검색해보세요.")

#### Community Type (최근 내역 있음)
```
┌────────────────────────────────┐
│     [검색창]                    │
├────────────────────────────────┤
│ 최근 방문/결제한 가게           │
├────────────────────────────────┤
│ 🍕 피자헛                       │
│ 피자 | 서울시 강남구...         │
├────────────────────────────────┤
│ ☕ 스타벅스                     │
│ 카페 | 서울시 서초구...         │
└────────────────────────────────┘
```
- **TableView**: 표시 (최근 주문한 가게)
- **Label**: 숨김
- **데이터**: `OrderRepository.getOrderList()` → 중복 제거

#### Community Type (최근 내역 없음)
```
┌────────────────────────────────┐
│     [검색창]                    │
├────────────────────────────────┤
│                                │
│    방문한 가게가 없어요.        │
│  가게를 직접 검색해서           │
│     입력해주세요.               │
│                                │
└────────────────────────────────┘
```
- **TableView**: 숨김
- **Label**: 표시 (안내 문구)

### B. 검색어가 있을 때 (검색 중)

#### 검색 결과 있음
```
┌────────────────────────────────┐
│     [피자]                      │
├────────────────────────────────┤
│ 검색 결과                       │
├────────────────────────────────┤
│ 🍕 피자헛 강남점                │
│ 피자 | 서울시 강남구...         │
├────────────────────────────────┤
│ 🍕 도미노피자 역삼점            │
│ 피자 | 서울시 강남구...         │
└────────────────────────────────┘
```
- **TableView**: 표시 (Header: "검색 결과")
- **Label**: 숨김
- **데이터**: `StoreRepository.searchStores(name: "피자")`

#### 검색 결과 없음
```
┌────────────────────────────────┐
│     [피자]                      │
├────────────────────────────────┤
│                                │
│  '피자'에 대한                  │
│  검색 결과가 없습니다.          │
│                                │
└────────────────────────────────┘
```
- **TableView**: 숨김
- **Label**: 표시 (검색 결과 없음)

---

## 사용 방법

### 1. HomeViewController에서 사용

```swift
// HomeCoordinator.swift
func showStoreSearch() {
    let viewModel = StoreSearchViewModel(viewType: .home)
    let viewController = StoreSearchViewController(
        viewModel: viewModel,
        viewType: .home
    )
    viewController.delegate = self
    navigationController.pushViewController(viewController, animated: true)
}

// HomeCoordinator + StoreSearchDelegate
extension HomeCoordinator: StoreSearchDelegate {
    func didSelectStore(_ store: StoreEntity) {
        // 가게 선택 시 처리
        showStoreDetail(storeId: store.storeId)
    }
}
```

### 2. CommunityPostViewController에서 사용

```swift
// CommunityCoordinator.swift
func showStoreSearch() {
    let viewModel = StoreSearchViewModel(viewType: .community)
    let viewController = StoreSearchViewController(
        viewModel: viewModel,
        viewType: .community
    )
    viewController.delegate = self
    navigationController.pushViewController(viewController, animated: true)
}

// CommunityCoordinator + StoreSearchDelegate
extension CommunityCoordinator: StoreSearchDelegate {
    func didSelectStore(_ store: StoreEntity) {
        // 가게 선택 시 처리 (예: 글 작성 화면에 전달)
        postViewController?.selectedStore = store
        navigationController.popViewController(animated: true)
    }
}
```

---

## 데이터 흐름

### Home Type (일반 검색)

```
User 입력 "피자"
    ↓
StoreSearchViewModel
    ↓
StoreRepository.searchStores(name: "피자")
    ↓
StoreAPI.User.searchStores
    ↓
[StoreEntity]
    ↓
UITableView 표시
```

### Community Type (최근 방문 가게)

```
viewDidLoad
    ↓
StoreSearchViewModel
    ↓
OrderRepository.getOrderList(status: nil)
    ↓
OrderAPI.getOrderList
    ↓
[OrderListItemEntity]
    ↓
각 order.store.toStoreEntity() 변환
    ↓
중복 제거 (Dictionary grouping)
    ↓
[StoreEntity]
    ↓
UITableView 표시 (Header: "최근 방문/결제한 가게")
```

---

## 중복 제거 로직

최근 주문 내역에서 같은 가게가 여러 번 나올 수 있으므로, **가게 ID 기준으로 중복 제거**합니다.

```swift
let uniqueStores = Dictionary(
    grouping: orderList,
    by: { $0.store.id }
)
.compactMap { $0.value.first?.store.toStoreEntity() }
```

**예시**:
```
주문 내역:
1. 피자헛 (2024-01-15)
2. 스타벅스 (2024-01-14)
3. 피자헛 (2024-01-10)  ← 중복

결과:
1. 피자헛 (최신 주문만)
2. 스타벅스
```

---

## OrderStoreInfoEntity → StoreEntity 변환

`OrderStoreInfoEntity`는 주문 API에서 반환되는 가게 정보이고, `StoreEntity`는 가게 검색/상세 API에서 사용하는 전체 정보입니다.

`toStoreEntity()` 메서드로 변환:

```swift
func toStoreEntity() -> StoreEntity {
    return StoreEntity(
        storeId: id,
        name: name,
        category: category,
        description: "",           // 주문 API에 없음
        address: "",               // 주문 API에 없음
        longitude: longitude,
        latitude: latitude,
        open: "",                  // 주문 API에 없음
        close: close,
        estimatedPickupTime: nil,
        parkingGuide: "",
        storeImageUrls: storeImageUrls,
        hashTags: hashTags,
        isPicchelin: false,        // 주문 API에 없음
        isPick: false,
        pickCount: 0,
        totalReviewCount: 0,
        totalOrderCount: 0,
        totalRating: 0.0,
        creator: nil,
        menuList: []               // 주문 API에 없음
    )
}
```

**주의**: 일부 필드는 주문 API에 없으므로 기본값으로 설정됩니다.

---

## 테스트 시나리오

### 1. Home Type 테스트

#### A. 초기 상태
1. HomeViewController → 검색 버튼 클릭
2. "원하시는 가게를 검색해보세요." 메시지 확인

#### B. 검색 성공
1. 검색창에 "피자" 입력
2. 300ms 후 검색 API 호출
3. 검색 결과 리스트 표시
4. 가게 선택 → `didSelectStore()` 콜백 확인

#### C. 검색 결과 없음
1. 검색창에 "zzzzz" 입력
2. "'zzzzz'에 대한 검색 결과가 없습니다." 메시지 확인

### 2. Community Type 테스트

#### A. 최근 주문 내역 있음
1. CommunityPostViewController → 가게 선택 버튼 클릭
2. 최근 주문한 가게 리스트 표시
3. Header: "최근 방문/결제한 가게" 확인
4. 가게 선택 → 글 작성 화면으로 돌아감

#### B. 최근 주문 내역 없음
1. 주문 내역이 없는 계정으로 로그인
2. "방문한 가게가 없어요..." 메시지 확인
3. 검색창에 가게 이름 입력하여 검색

#### C. 검색 전환
1. 최근 주문 내역 표시 중
2. 검색창에 텍스트 입력
3. 검색 결과로 전환
4. 검색창 비우기
5. 다시 최근 주문 내역으로 전환

---

## 코드 스타일

### 1. Then 사용 안 함
```swift
// ❌ Bad
private let label = UILabel().then {
    $0.font = AppFont.body1
}

// ✅ Good
private let label: UILabel = {
    let label = UILabel()
    label.font = AppFont.body1
    return label
}()
```

### 2. DesignSystem 사용
```swift
// ✅ Good
label.font = AppFont.body1
label.textColor = AppColor.gray100
imageView.image = AppImage.chevron
```

### 3. SnapKit 사용
```swift
// ✅ Good
label.snp.makeConstraints {
    $0.top.equalToSuperview().inset(16)
    $0.leading.trailing.equalToSuperview().inset(20)
}
```

### 4. 메서드 분리
```swift
// ✅ Good
override func setupUI() { }
override func setupConstraints() { }
override func bind() { }
private func updateViewState(_ state: StoreSearchViewState) { }
```

---

## 트러블슈팅

### 문제: Community Type에서 최근 가게가 안 보임
**원인**: 주문 내역이 없거나 API 에러
**해결**:
1. OrderRepository 로그 확인
2. 테스트 계정으로 주문 생성 후 테스트

### 문제: 검색 결과가 너무 느림
**원인**: Debounce 시간 또는 서버 응답 지연
**해결**:
1. Debounce 시간 조정 (현재 300ms)
2. 로딩 인디케이터 확인

### 문제: 가게 선택 시 Delegate 호출 안 됨
**원인**: delegate weak 참조가 nil
**해결**:
```swift
let viewController = StoreSearchViewController(...)
viewController.delegate = self  // ✅ 필수!
```

---

## 향후 개선 사항

1. **캐싱**: 검색 결과 캐싱으로 성능 향상
2. **최근 검색어**: 검색 히스토리 저장
3. **정렬/필터**: 거리순, 평점순 정렬
4. **무한 스크롤**: 검색 결과 페이지네이션
5. **지도 뷰**: 검색 결과를 지도에 표시

---

## 관련 파일

### Models
- `Odaeri_User/Presentation/Common/Models/StoreSearchViewType.swift`

### Protocols
- `Odaeri_User/Presentation/Common/Protocols/StoreSearchDelegate.swift`

### ViewModels
- `Odaeri_User/Presentation/Common/ViewModels/StoreSearchViewModel.swift`

### Views
- `Odaeri_User/Presentation/Common/Views/StoreSearchViewController.swift`
- `Odaeri_User/Presentation/Common/Views/StoreSearchCell.swift`

### Entities
- `Shared/Network/Models/Entities/StoreEntity.swift`
- `Shared/Network/Models/Entities/OrderEntity.swift` (OrderStoreInfoEntity)

### Repositories
- `Odaeri_User/Domain/RepositoryProtocols/StoreRepository.swift`
- `Odaeri_User/Domain/RepositoryProtocols/OrderRepository.swift`

---

## 문의

구현 관련 문의사항은 프로젝트 담당자에게 연락해주세요.
