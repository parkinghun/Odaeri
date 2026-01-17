# 커뮤니티 게시글 상세 화면 구현 계획

## 📋 개요
- **목적**: 커뮤니티 게시글 상세 정보를 표시하는 화면 구현
- **트리거**: CommunityPostCell의 titleStackView 또는 contentLabel 탭
- **데이터 소스**: `CommunityPostAPI.fetchPostDetail(postId:)`

---

## 🎯 구현 단계

### Phase 1: 셀 탭 이벤트 연결
- [ ] CommunityPostCell에 contentTapPublisher 추가
- [ ] titleStackView + contentLabel을 포함하는 containerView 생성
- [ ] UITapGestureRecognizer로 탭 이벤트 감지
- [ ] CommunityViewController에서 이벤트 구독 및 Coordinator 호출

### Phase 2: UI 컴포넌트 구현 (UI만 먼저)
- [ ] **CommunityPostDetailViewController** 생성
  - ScrollView + StackView 기반 레이아웃
  - 작성자 정보 영역 (재사용: CommunityCreatorInfoView)
  - 미디어 배너 영역 (재사용: CommunityMediaGridView 또는 새 PageableImageView)
  - 제목 + 본문 영역
  - 가게 정보 카드
  - 좋아요/댓글 인터랙션 바
  - 댓글 리스트 영역

- [ ] **CommunityStoreDetailCard** 커스텀 뷰 생성
  - 가게 이름
  - 평점 (total_rating) + 리뷰 수 (IconLabelView)
  - 피슐랭 아이콘 (is_picchelin)
  - 픽 카운트 (IconLabelView)
  - 해시태그 가로 스크롤 뷰
  - 탭 제스처로 가게 상세 이동

- [ ] **CommentCell** 구현
  - 댓글 작성자 프로필 + 닉네임
  - 댓글 내용
  - 작성 시간
  - 답글(replies) 계층 구조 표현

### Phase 3: ViewModel 및 데이터 바인딩 (다음 단계)
- [ ] CommunityPostDetailViewModel 생성
- [ ] fetchPostDetail API 호출 로직
- [ ] Input/Output 구조 정의
- [ ] Combine 바인딩

### Phase 4: Coordinator 연동
- [ ] CommunityCoordinator에 showPostDetail(postId:) 메서드 추가
- [ ] 가게 카드 탭 → showStoreDetail(storeId:) 연결
- [ ] 수정 버튼 → openEditPost(with:) 연결
- [ ] 삭제 버튼 → deletePost(postId:) 연결

---

## 🎨 UI 구조 (StackView 기반)

```
ScrollView
└── MainStackView (vertical)
    ├── CreatorInfoView (재사용)
    ├── MediaBannerView (페이징 가능한 이미지 뷰)
    ├── TitleLabel (AppFont.title1)
    ├── ContentLabel (AppFont.body1, numberOfLines = 0)
    ├── InteractionBar (좋아요 + 댓글 수)
    ├── Divider
    ├── StoreDetailCard ⭐
    │   ├── StoreImageView
    │   ├── StoreNameLabel
    │   ├── RatingStackView
    │   │   ├── StarIcon + RatingLabel (IconLabelView)
    │   │   ├── ReviewCountLabel (IconLabelView)
    │   │   └── PichelinBadge (조건부)
    │   ├── PickCountView (IconLabelView)
    │   └── HashTagScrollView
    ├── Divider
    └── CommentsSection
        └── CommentCell (댓글 + 답글 계층)
```

---

## 📦 필요한 파일 목록

### 새로 생성할 파일
1. `Odaeri_User/Presentation/Community/Views/CommunityPostDetailViewController.swift`
2. `Odaeri_User/Presentation/Community/ViewModels/CommunityPostDetailViewModel.swift`
3. `Odaeri_User/Presentation/Community/Views/CommunityStoreDetailCard.swift`
4. `Odaeri_User/Presentation/Community/Views/CommunityCommentCell.swift` (옵션)
5. `Odaeri_User/Presentation/Community/Views/CommunityMediaBannerView.swift` (옵션)

### 수정할 파일
1. `CommunityPostCell.swift` - contentTapPublisher 추가
2. `CommunityViewController.swift` - 탭 이벤트 구독
3. `CommunityCoordinator.swift` - showPostDetail 메서드 추가

---

## 🔧 기술 요구사항

### 이미지 로딩
- UIImageView+Extension 참고
- Placeholder 적용
- 상대 경로(/data/posts/...)인 경우 Base URL 결합

### 날짜 포맷
- 기존 ISO8601 DateFormatter 사용
- `toRelativeTime` Extension 활용

### 좋아요 상태
- `is_like` 값에 따라 하트 아이콘 활성화
- 낙관적 UI 업데이트 (optimistic update)
- LikeButton 참곷

### 가게 정보 카드 스타일
- 배경색: AppColor.gray15
- 모서리: cornerRadius = 12
- 그림자 또는 border로 시각적 구분
- 탭 가능 (Tap Gesture)

---

## 📊 데이터 모델 (CommunityPostEntity)

```swift
struct CommunityPostEntity {
    let postId: String
    let creator: CreatorEntity        // 프로필, 닉네임
    let files: [String]               // 이미지/비디오 URL 배열
    let title: String
    let content: String
    let likeCount: Int
    let isLike: Bool
    let createdAt: String?            // ISO8601
    let store: StoreEntity            // 가게 정보
    let comments: [CommentEntity]?    // 댓글 배열
}

struct StoreEntity {
    let storeId: String
    let name: String
    let totalRating: Double           // total_rating
    let reviewCount: Int              // reviews 배열 count
    let isPicchelin: Bool             // is_picchelin
    let pickCount: Int                // picks 배열 count
    let hashTags: [String]
    let storeImageUrls: [String]
    let category: String
    let address: String
}
```

---

## 🎯 우선순위 (현재 작업)

### ✅ 현재 작업: Phase 1 + Phase 2 (UI만)
1. CommunityPostCell에 탭 이벤트 추가
2. CommunityPostDetailViewController UI 구현 (로직 제외)
3. CommunityStoreDetailCard UI 구현
4. IconLabelView 재사용

### ⏸️ 다음 작업: Phase 3 + Phase 4
1. ViewModel 로직 구현
2. API 바인딩
3. Coordinator 연결
4. 수정/삭제 기능

---

## 📝 Notes
- **재사용 컴포넌트**: CommunityCreatorInfoView, IconLabelView
- **새 컴포넌트**: CommunityStoreDetailCard, CommunityMediaBannerView
- **레이아웃 방식**: ScrollView + StackView (Compositional Layout 대신 간단하게)
- **미디어 처리**: 기존 CommunityMediaGridView 로직 참고 (video/image 구분)
