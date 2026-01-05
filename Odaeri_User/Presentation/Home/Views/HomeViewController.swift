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
    weak var coordinator: HomeCoordinator?

    private let locationView = LocationView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.brightSprout
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private typealias DataSource = UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>

    private var dataSource: DataSource?
    private var categoryCell: CategoryCell?
    private var topHeaderView: TopHeaderView?

    private var bannerCount: Int = 0
    private let userScrolledBannerSubject = PassthroughSubject<Int, Never>()
    private let likeTapSubject = PassthroughSubject<LikeButton.TapEvent, Never>()

    private var currentLocation: CLLocation?
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppColor.brightSprout
        
        view.addSubview(locationView)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        
        configureDataSource()
        
        locationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.height.equalTo(32)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(locationView.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private let categorySelectedSubject = PassthroughSubject<Category?, Never>()
    
    override func bind() {
        super.bind()
        
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let refreshSubject = PassthroughSubject<Void, Never>()
        
        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            refreshTriggered: refreshSubject.eraseToAnyPublisher(),
            userScrolledBanner: userScrolledBannerSubject.eraseToAnyPublisher(),
            storeLikeToggled: likeTapSubject.eraseToAnyPublisher()
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
                self?.topHeaderView?.configure(with: keywords)
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

        // 현재 위치 업데이트
        output.currentLocation
            .sink { [weak self] location in
                guard let self else { return }
                self.currentLocation = location
                
                if let snapshot = self.dataSource?.snapshot(), snapshot.numberOfItems > 0 {
                    self.dataSource?.apply(snapshot, animatingDifferences: false)
                }
            }
            .store(in: &cancellables)

        // ViewDidLoad 트리거
        viewDidLoadSubject.send()
    }
    
    private func updateBanners(_ banners: [BannerEntity]) {
        bannerCount = banners.count
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .banner))
        let items = banners.map { HomeSectionItem.banner($0) }
        snapshot.appendItems(items, toSection: .banner)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func scrollToBanner(at index: Int) {
        guard bannerCount > 0 else { return }
        
        let bannerIndexPath = IndexPath(item: index, section: HomeSection.banner.rawValue)
        collectionView.scrollToItem(at: bannerIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    private func updatePopularStores(_ stores: [StoreEntity]) {
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .popularRestaurants))
        let items = stores.map { HomeSectionItem.popularRestaurants($0) }
        snapshot.appendItems(items, toSection: .popularRestaurants)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func updateMyPickupStores(_ stores: [StoreEntity]) {
        guard var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .myPickupStores))
        let items = stores.map { HomeSectionItem.myPickupStore($0) }
        snapshot.appendItems(items, toSection: .myPickupStores)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func revertLikeForStore(storeId: String) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? PopularShopCell,
               let item = dataSource?.itemIdentifier(for: indexPath),
               case .popularRestaurants(let store) = item,
               store.storeId == storeId {
                cell.revertLike()
                return
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? ShopListCell,
               let item = dataSource?.itemIdentifier(for: indexPath),
               case .myPickupStore(let store) = item,
               store.storeId == storeId {
                cell.revertLike()
                return
            }
        }
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
        section.orthogonalScrollingBehavior = .groupPaging
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
            cell.configure(with: store, currentLocation: self.currentLocation)

            // 좋아요 버튼 이벤트 연결
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.likeTapSubject.send(event)
                }
                .store(in: &cell.cancellables)
        }
        
        let bannerCellRegistration = UICollectionView.CellRegistration<BannerCell, BannerEntity> { [weak self] cell, indexPath, banner in
            guard let self = self else { return }
            cell.configure(with: banner, currentIndex: indexPath.item, totalCount: self.bannerCount)
        }
        
        let shopListCellRegistration = UICollectionView.CellRegistration<ShopListCell, StoreEntity> { [weak self] cell, indexPath, store in
            guard let self = self else { return }
            cell.configure(with: store, currentLocation: self.currentLocation)

            // 좋아요 버튼 이벤트 연결
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.likeTapSubject.send(event)
                }
                .store(in: &cell.cancellables)
        }
        
        let topHeaderRegistration = UICollectionView.SupplementaryRegistration<TopHeaderView>(
            elementKind: "TopHeader"
        ) { [weak self] supplementaryView, _, _ in
            guard let self = self else { return }
            self.topHeaderView = supplementaryView
        }
        
        let shopListHeaderRegistration = UICollectionView.SupplementaryRegistration<ShopListHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, elementKind, indexPath in
            // ShopListHeaderView는 자체적으로 UI 구성
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
            case .banner(let banner):
                return collectionView.dequeueConfiguredReusableCell(using: bannerCellRegistration, for: indexPath, item: banner)
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

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .popularRestaurants(let store), .myPickupStore(let store):
            coordinator?.showStoreDetail(storeId: store.storeId)
            
        case .banner(let banner):
            if banner.action.isWebView,
               let path = banner.action.webViewPath {
                coordinator?.showEventWeb(path: path)
            }
            
        case .category:
            break
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        notifyUserScrolledBanner()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            notifyUserScrolledBanner()
        }
    }
    
    private func notifyUserScrolledBanner() {
        guard bannerCount > 0 else { return }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
            .filter { $0.section == HomeSection.banner.rawValue }
            .sorted()
        
        if let firstVisibleBannerIndexPath = visibleIndexPaths.first {
            userScrolledBannerSubject.send(firstVisibleBannerIndexPath.item)
        }
    }
}
