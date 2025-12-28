//
//  HomeViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class HomeViewController: BaseViewController<HomeViewModel> {
    weak var coordinator: HomeCoordinator?
    
    /*
     실시간 인기 맛집
     배너
     
     내가 픽업가게 (거리순)
     (픽슐랭 / 마이픽)
     */
    
    private let locationView = LocationView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let searchBar = SearchBar()
    private let trendingSearchTickerView = TrendingSearchTickerView()

    private lazy var modalMainView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private let categoryView = CategoryView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private typealias DataSource = UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>

    private var dataSource: DataSource?

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.brightSprout

        view.addSubview(locationView)
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addSubview(searchBar)
        contentView.addSubview(trendingSearchTickerView)
        contentView.addSubview(modalMainView)

        modalMainView.addSubview(categoryView)
        modalMainView.addSubview(collectionView)

        configureDataSource()

        locationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.height.equalTo(32)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(locationView.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        trendingSearchTickerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        modalMainView.snp.makeConstraints {
            $0.top.equalTo(trendingSearchTickerView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
            $0.bottom.equalToSuperview()
        }

        categoryView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(categoryView.snp.bottom).offset(AppSpacing.medium)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func bind() {
        super.bind()

        let input = HomeViewModel.Input()
        let output = viewModel.transform(input: input)

        locationView.tapPublisher
            .sink { [weak self] in
                // TODO: 위치 선택 화면으로 이동
                print("Location tapped")
            }
            .store(in: &cancellables)

        categoryView.categoryTapPublisher
            .sink { category in
                print("Selected category: \(category.title)")
                // TODO: 선택된 카테고리에 따라 필터링
            }
            .store(in: &cancellables)
    }
}

// MARK: - CollectionView Layout
private extension HomeViewController {
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let section = HomeSection(rawValue: sectionIndex) else { return nil }

            switch section {
            case .trendingRestaurants:
                return self?.createTrendingRestaurantsSection()
            case .banner:
                return self?.createBannerSection()
            case .myPickupStores:
                return self?.createMyPickupStoresSection()
            }
        }
    }

    func createTrendingRestaurantsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(200),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = AppSpacing.medium
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: AppSpacing.large,
            trailing: AppSpacing.screenMargin
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    func createBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.9),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.interGroupSpacing = AppSpacing.medium
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: AppSpacing.large,
            trailing: AppSpacing.screenMargin
        )

        return section
    }

    func createMyPickupStoresSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = AppSpacing.medium
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: AppSpacing.large,
            trailing: AppSpacing.screenMargin
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }
}

// MARK: - CollectionView DataSource
private extension HomeViewController {
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, HomeSectionItem> { cell, indexPath, item in
            // TODO: Cell 구성 (나중에 커스텀 셀로 교체)
            var config = UIListContentConfiguration.cell()
            switch item {
            case .trendingRestaurant(let store):
                config.text = store.name
            case .banner(let banner):
                config.text = banner.name
            case .myPickupStore(let store):
                config.text = store.name
            }
            cell.contentConfiguration = config
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
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }

        // 초기 데이터 적용
        applySnapshot()
    }

    func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections(HomeSection.allCases)

        // TODO: 실제 데이터로 교체
        let mockTrendingRestaurants = [
            HomeSectionItem.trendingRestaurant(
                StoreEntity(
                    storeId: "1",
                    name: "새싹 도넛 가게",
                    category: "디저트",
                    description: "",
                    address: "",
                    longitude: 0,
                    latitude: 0,
                    open: "7PM",
                    close: "10PM",
                    parkingGuide: "",
                    storeImageUrls: [],
                    hashTags: [],
                    pickCount: 126,
                    totalOrderCount: 135
                )
            ),
            HomeSectionItem.trendingRestaurant(
                StoreEntity(
                    storeId: "2",
                    name: "케이크 바이 새싹",
                    category: "디저트",
                    description: "",
                    address: "",
                    longitude: 0,
                    latitude: 0,
                    open: "6PM",
                    close: "11PM",
                    parkingGuide: "",
                    storeImageUrls: [],
                    hashTags: []
                )
            )
        ]

        let mockBanners = [
            HomeSectionItem.banner(BannerEntity(name: "배너1", imageUrl: "", action: .webView(path: "")))
        ]

        let mockStores = [
            HomeSectionItem.myPickupStore(
                StoreEntity(
                    storeId: "3",
                    name: "새싹 마카롱 영등포직영점",
                    category: "디저트",
                    description: "",
                    address: "1.3km",
                    longitude: 0,
                    latitude: 0,
                    open: "7PM",
                    close: "10PM",
                    parkingGuide: "",
                    storeImageUrls: [],
                    hashTags: ["#돈가를", "#티라미수"],
                    pickCount: 155,
                    totalReviewCount: 145,
                    totalOrderCount: 288,
                    totalRating: 4.9
                )
            )
        ]

        snapshot.appendItems(mockTrendingRestaurants, toSection: .trendingRestaurants)
        snapshot.appendItems(mockBanners, toSection: .banner)
        snapshot.appendItems(mockStores, toSection: .myPickupStores)

        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
