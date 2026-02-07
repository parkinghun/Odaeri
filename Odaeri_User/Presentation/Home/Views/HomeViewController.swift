//
//  HomeViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit
import CoreLocation

final class HomeViewController: BaseViewController<HomeViewModel> {
    override var navigationBarHidden: Bool { true }
    private let notificationCenter: NotificationCenter
    private let routeManager: RouteManaging
    private let locationView = LocationView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.brightSprout2
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private typealias DataSource = UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>

    private var dataSource: DataSource?
    private var categoryCell: CategoryCell?
    private var topHeaderView: TopHeaderView?
    private var shopListHeaderView: ShopListHeaderView?

    private var bannerCount: Int = 0
    private let userScrolledBannerSubject = PassthroughSubject<Int, Never>()
    private let likeTapSubject = PassthroughSubject<LikeButton.TapEvent, Never>()
    private let bannerSelectedSubject = PassthroughSubject<BannerEntity, Never>()
    private let storeSelectedSubject = PassthroughSubject<String, Never>()
    private let searchBarTappedSubject = PassthroughSubject<Void, Never>()
    private let sortTypeChangedSubject = PassthroughSubject<String, Never>()
    private let filterTypeChangedSubject = PassthroughSubject<(isPicchelin: Bool?, isPick: Bool?), Never>()
    private var bannerCarouselCell: BannerCarouselCell?

    private var currentLocation: CLLocation?
    private var storeCache: [String: StoreEntity] = [:]
    private var lastTabBarInset: CGFloat = 0
    private var currentKeywords: [String] = []

    init(
        viewModel: HomeViewModel,
        notificationCenter: NotificationCenter,
        routeManager: RouteManaging
    ) {
        self.notificationCenter = notificationCenter
        self.routeManager = routeManager
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppColor.brightSprout2
        
        view.addSubview(locationView)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        setKeyboardDismissMode(.onDrag, for: collectionView)
        configureDataSource()
        
        locationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.height.equalTo(32)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(locationView.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewInsetsIfNeeded()
    }
    
    private let categorySelectedSubject = PassthroughSubject<Category?, Never>()
    private let keywordSearchTappedSubject = PassthroughSubject<String, Never>()

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let refreshSubject = PassthroughSubject<Void, Never>()

        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            searchBarTapped: searchBarTappedSubject.eraseToAnyPublisher(),
            keywordSearchTapped: keywordSearchTappedSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            refreshTriggered: refreshSubject.eraseToAnyPublisher(),
            userScrolledBanner: userScrolledBannerSubject.eraseToAnyPublisher(),
            bannerSelected: bannerSelectedSubject.eraseToAnyPublisher(),
            storeLikeToggled: likeTapSubject.eraseToAnyPublisher(),
            storeSelected: storeSelectedSubject.eraseToAnyPublisher(),
            sortTypeChanged: sortTypeChangedSubject.eraseToAnyPublisher(),
            filterTypeChanged: filterTypeChangedSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input: input)
        
        // 위치 선택
        locationView.tapPublisher
            .sink { _ in
                // TODO: 위치 선택 화면으로 이동
                print("Location tapped")
            }
            .store(in: &cancellables)
        
        // 로딩 상태
        output.isLoading
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)
        
        // 에러 처리
        output.error
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)
        
        // 인기 검색어 업데이트
        output.popularKeywords
            .sink { [weak self] keywords in
                guard let self = self else { return }
                self.currentKeywords = keywords
                self.topHeaderView?.configure(with: keywords)
            }
            .store(in: &cancellables)
        
        // 배너 업데이트
        output.banners
            .sink { [weak self] banners in
                self?.updateBanners(banners)
            }
            .store(in: &cancellables)
        
        // 배너 인덱스 변경 (자동 슬라이드)
        output.currentBannerIndex
            .sink { [weak self] index in
                self?.scrollToBanner(at: index)
            }
            .store(in: &cancellables)
        
        // 실시간 인기 맛집 업데이트
        output.popularStores
            .sink { [weak self] stores in
                self?.updatePopularStores(stores)
            }
            .store(in: &cancellables)
        
        // 내가 픽업 가게 업데이트
        output.myPickupStores
            .sink { [weak self] stores in
                self?.updateMyPickupStores(stores)
            }
            .store(in: &cancellables)
        
        // 좋아요 토글 실패 시 되돌리기
        output.likeToggleFailed
            .sink { [weak self] storeId in
                self?.revertLikeForStore(storeId: storeId)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .storeLikeUpdated)
            .compactMap { $0.userInfo?["info"] as? StoreLikeUpdateInfo }
            .sink { [weak self] info in
                self?.applyStoreLikeUpdate(
                    storeId: info.storeId,
                    isPicked: info.isPick,
                    pickCount: info.pickCount
                )
            }
            .store(in: &cancellables)

        // 현재 위치 업데이트
        output.currentLocation
            .sink { [weak self] location in
                guard let self else { return }
                self.currentLocation = location
                self.reconfigureVisibleStoreCells()
            }
            .store(in: &cancellables)

        // ViewDidLoad 트리거
        viewDidLoadSubject.send()
    }
    
    private func updateBanners(_ banners: [BannerEntity]) {
        bannerCount = banners.count
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .banner))
        if !banners.isEmpty {
            snapshot.appendItems([.banner(banners)], toSection: .banner)
        }
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func scrollToBanner(at index: Int) {
        guard bannerCount > 0 else { return }
        if let cell = bannerCarouselCell {
            cell.scrollToBanner(at: index)
        } else if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: HomeSection.banner.rawValue)) as? BannerCarouselCell {
            bannerCarouselCell = cell
            cell.scrollToBanner(at: index)
        }
    }
    
    private func updatePopularStores(_ stores: [StoreEntity]) {
        stores.forEach { storeCache[$0.storeId] = $0 }
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .popularRestaurants))
        let items = stores.map { HomeSectionItem.popularRestaurants($0) }
        snapshot.appendItems(items, toSection: .popularRestaurants)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func updateMyPickupStores(_ stores: [StoreEntity]) {
        stores.forEach { storeCache[$0.storeId] = $0 }
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .myPickupStores))
        let items = stores.map { HomeSectionItem.myPickupStore($0) }
        snapshot.appendItems(items, toSection: .myPickupStores)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func revertLikeForStore(storeId: String) {
        revertStoreLikeUpdate(storeId: storeId)
    }

    private func applyStoreLikeUpdate(storeId: String, isPicked: Bool, pickCount: Int? = nil) {
        guard let baseStore = storeCache[storeId] ?? findStoreInSnapshot(storeId: storeId) else { return }
        let updatedPickCount = pickCount ?? max(0, baseStore.pickCount + (isPicked ? 1 : -1))
        let updatedStore = baseStore.updatingPick(isPick: isPicked, pickCount: updatedPickCount)
        storeCache[storeId] = updatedStore
        reconfigureStoreCells(storeId: storeId)
    }

    private func revertStoreLikeUpdate(storeId: String) {
        guard let baseStore = storeCache[storeId] ?? findStoreInSnapshot(storeId: storeId) else { return }
        let revertedPickCount = max(0, baseStore.pickCount + (baseStore.isPick ? -1 : 1))
        let revertedStore = baseStore.updatingPick(isPick: !baseStore.isPick, pickCount: revertedPickCount)
        storeCache[storeId] = revertedStore
        reconfigureStoreCells(storeId: storeId)
    }

    private func findStoreInSnapshot(storeId: String) -> StoreEntity? {
        guard let snapshot = dataSource?.snapshot() else { return nil }
        for item in snapshot.itemIdentifiers {
            switch item {
            case .popularRestaurants(let store) where store.storeId == storeId:
                return store
            case .myPickupStore(let store) where store.storeId == storeId:
                return store
            default:
                break
            }
        }
        return nil
    }

    private func reconfigureStoreCells(storeId: String) {
        guard var snapshot = dataSource?.snapshot() else { return }
        let items = snapshot.itemIdentifiers.compactMap { item -> HomeSectionItem? in
            switch item {
            case .popularRestaurants(let store) where store.storeId == storeId:
                return item
            case .myPickupStore(let store) where store.storeId == storeId:
                return item
            default:
                return nil
            }
        }
        guard !items.isEmpty else { return }
        snapshot.reconfigureItems(items)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func reconfigureVisibleStoreCells() {
        guard var snapshot = dataSource?.snapshot() else { return }
        let items = collectionView.indexPathsForVisibleItems.compactMap { indexPath -> HomeSectionItem? in
            guard let item = dataSource?.itemIdentifier(for: indexPath) else { return nil }
            switch item {
            case .popularRestaurants, .myPickupStore:
                return item
            default:
                return nil
            }
        }
        guard !items.isEmpty else { return }
        snapshot.reconfigureItems(items)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - CollectionView Layout
private extension HomeViewController {
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let section = HomeSection(rawValue: sectionIndex) else { return nil }
            
            switch section {
            case .topHeader:
                return self?.createTopHeaderSection()
            case .popularRestaurants:
                return self?.createTrendingRestaurantsSection()
            case .banner:
                return self?.createBannerSection()
            case .myPickupStores:
                return self?.createMyPickupStoresSection()
            }
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        layout.configuration = config
        layout.register(TopHeaderBackgroundDecorationView.self, forDecorationViewOfKind: "TopHeaderBackgroundDecorationView")
        layout.register(NormalBackgroundDecorationView.self, forDecorationViewOfKind: "NormalBackgroundDecorationView")
        
        return layout
    }
    
    func createTopHeaderSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(110)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(110)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
        )
        
        // Top Header (SearchBar + Ticker)
        let topHeaderSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let topHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: topHeaderSize,
            elementKind: "TopHeader",
            alignment: .top
        )
        topHeader.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: 0,
            trailing: AppSpacing.screenMargin
        )
        
        section.boundarySupplementaryItems = [topHeader]
        
        return section
    }
    
    func createTrendingRestaurantsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(176)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(240),
            heightDimension: .absolute(176)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = AppSpacing.medium
        section.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.medium,
            leading: AppSpacing.screenMargin,
            bottom: AppSpacing.large,
            trailing: AppSpacing.screenMargin
        )
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(32)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
        )
        section.boundarySupplementaryItems = [header]
        
        let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "NormalBackgroundDecorationView")
        section.decorationItems = [backgroundDecoration]
        
        return section
    }
    
    func createBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        section.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.medium,
            leading: .zero,
            bottom: AppSpacing.small,
            trailing: .zero
        )
        
        let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "NormalBackgroundDecorationView")
        section.decorationItems = [backgroundDecoration]
        
        return section
    }
    
    func createMyPickupStoresSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(235)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(235)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: AppSpacing.large,
            trailing: 0
        )
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(64)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: 0,
            trailing: AppSpacing.screenMargin
        )
        section.boundarySupplementaryItems = [header]
        
        let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "NormalBackgroundDecorationView")
        section.decorationItems = [backgroundDecoration]
        
        return section
    }
}

// MARK: - CollectionView DataSource
private extension HomeViewController {
    func configureDataSource() {
        let categoryCellRegistration = UICollectionView.CellRegistration<CategoryCell, HomeSectionItem> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            self.categoryCell = cell
            
            // Category 선택 바인딩
            cell.categoryTapPublisher
                .sink { [weak self] category in
                    self?.categorySelectedSubject.send(category)
                }
                .store(in: &self.cancellables)
        }
        
        let popularShopCellRegistration = UICollectionView.CellRegistration<PopularShopCell, StoreEntity> { [weak self] cell, indexPath, store in
            guard let self = self else { return }
            let resolvedStore = self.storeCache[store.storeId] ?? store
            let distanceInfo = self.makeDistanceInfo(for: resolvedStore)
            cell.configure(with: resolvedStore, distanceText: distanceInfo.distanceText, stepsText: distanceInfo.stepsText)

            // 좋아요 버튼 이벤트 연결
            cell.cancellables.removeAll()
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.applyStoreLikeUpdate(storeId: event.storeId, isPicked: event.newState)
                    self?.likeTapSubject.send(event)
                }
                .store(in: &cell.cancellables)
        }
        
        let bannerCarouselCellRegistration = UICollectionView.CellRegistration<BannerCarouselCell, [BannerEntity]> { [weak self] cell, _, banners in
            guard let self = self else { return }
            self.bannerCarouselCell = cell
            cell.configure(
                banners: banners,
                onUserScrolled: { [weak self] index in
                    self?.userScrolledBannerSubject.send(index)
                },
                onBannerSelected: { [weak self] banner in
                    self?.bannerSelectedSubject.send(banner)
                }
            )
        }
        
        let shopListCellRegistration = UICollectionView.CellRegistration<ShopListCell, StoreEntity> { [weak self] cell, indexPath, store in
            guard let self = self else { return }
            let resolvedStore = self.storeCache[store.storeId] ?? store
            let distanceInfo = self.makeDistanceInfo(for: resolvedStore)
            cell.configure(with: resolvedStore, distanceText: distanceInfo.distanceText, stepsText: distanceInfo.stepsText)

            // 좋아요 버튼 이벤트 연결
            cell.cancellables.removeAll()
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.applyStoreLikeUpdate(storeId: event.storeId, isPicked: event.newState)
                    self?.likeTapSubject.send(event)
                }
                .store(in: &cell.cancellables)
        }
        
        let topHeaderRegistration = UICollectionView.SupplementaryRegistration<TopHeaderView>(
            elementKind: "TopHeader"
        ) { [weak self] supplementaryView, _, _ in
            guard let self = self else { return }

            self.topHeaderView = supplementaryView
            supplementaryView.configure(with: self.currentKeywords)

            supplementaryView.searchBarTapPublisher
                .throttle(for: .seconds(0.5), scheduler: RunLoop.main, latest: false)
                .sink { [weak self] _ in
                    self?.searchBarTappedSubject.send()
                }
                .store(in: &supplementaryView.cancellables)

            supplementaryView.keywordSearchTapPublisher
                .throttle(for: .seconds(0.5), scheduler: RunLoop.main, latest: false)
                .sink { [weak self] keyword in
                    self?.keywordSearchTappedSubject.send(keyword)
                }
                .store(in: &supplementaryView.cancellables)
        }
        
        let shopListHeaderRegistration = UICollectionView.SupplementaryRegistration<ShopListHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }

            self.shopListHeaderView = supplementaryView

            supplementaryView.sortTypePublisher
                .sink { [weak self] sortType in
                    self?.sortTypeChangedSubject.send(sortType.rawValue)
                }
                .store(in: &supplementaryView.cancellables)

            supplementaryView.filterTypePublisher
                .sink { [weak self] filterType in
                    let filter: (isPicchelin: Bool?, isPick: Bool?)
                    switch filterType {
                    case .all:
                        filter = (nil, nil)
                    case .picchelin:
                        filter = (true, nil)
                    case .myPick:
                        filter = (nil, true)
                    }
                    self?.filterTypeChangedSubject.send(filter)
                }
                .store(in: &supplementaryView.cancellables)

            supplementaryView.applyInitialFilterIfNeeded()
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, elementKind, indexPath in
            var config = UIListContentConfiguration.plainHeader()
            if let section = HomeSection(rawValue: indexPath.section) {
                config.text = section.title
                config.textProperties.font = AppFont.body2Bold
                config.textProperties.color = AppColor.gray90
            }
            supplementaryView.contentConfiguration = config
        }
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .category:
                return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: item)
            case .popularRestaurants(let store):
                return collectionView.dequeueConfiguredReusableCell(using: popularShopCellRegistration, for: indexPath, item: store)
            case .banner(let banners):
                return collectionView.dequeueConfiguredReusableCell(using: bannerCarouselCellRegistration, for: indexPath, item: banners)
            case .myPickupStore(let store):
                return collectionView.dequeueConfiguredReusableCell(using: shopListCellRegistration, for: indexPath, item: store)
            }
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case "TopHeader":
                return collectionView.dequeueConfiguredReusableSupplementary(using: topHeaderRegistration, for: indexPath)
            case UICollectionView.elementKindSectionHeader:
                if let section = HomeSection(rawValue: indexPath.section), section == .myPickupStores {
                    return collectionView.dequeueConfiguredReusableSupplementary(using: shopListHeaderRegistration, for: indexPath)
                } else {
                    return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
                }
            default:
                return nil
            }
        }
        
        applySnapshot()
    }
    
    func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections(HomeSection.allCases)
        snapshot.appendItems([.category], toSection: .topHeader)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

private extension HomeViewController {
    func makeDistanceInfo(for store: StoreEntity) -> (distanceText: String, stepsText: String) {
        guard let currentLocation = currentLocation else {
            return ("--km", "--보")
        }

        let distance = routeManager.calculateDistance(
            from: currentLocation.coordinate,
            to: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
        )
        let distanceText = String(format: "%.1fkm", distance)
        let estimatedSteps = routeManager.calculateEstimatedSteps(distanceInKm: distance)
        let stepsText = "\(estimatedSteps)보"
        return (distanceText, stepsText)
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .popularRestaurants(let store), .myPickupStore(let store):
            storeSelectedSubject.send(store.storeId)
            
        case .banner:
            break
        case .category:
            break
        }
    }

    private func updateCollectionViewInsetsIfNeeded() {
        let tabBarInset = currentTabBarInset()
        guard tabBarInset != lastTabBarInset else { return }
        lastTabBarInset = tabBarInset
        collectionView.contentInset.bottom = tabBarInset
        collectionView.verticalScrollIndicatorInsets.bottom = tabBarInset
    }

    private func currentTabBarInset() -> CGFloat {
        if let tabBarController = tabBarController as? CustomTabBarController {
            let tabBar = tabBarController.view.subviews.first { $0 is CustomTabBar }
            if let tabBar {
                return tabBar.frame.height
            }
        }
        return 60 + view.safeAreaInsets.bottom
    }
}
