//
//  ShopDetailViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit
import Combine
import SnapKit

final class ShopDetailViewController: BaseViewController<ShopDetailViewModel> {
    enum Section: Hashable {
        case imageCarousel
        case storeInfo
        case menu(category: String)
    }

    enum Item: Hashable {
        case imageCarousel(StoreEntity)
        case storeInfo(StoreEntity)
        case menu(MenuEntity)
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.gray15
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private lazy var likeButton: LikeButton = {
        let button = LikeButton()
        button.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        return button
    }()

    private var currentStore: StoreEntity?
    private let likeTapSubject = PassthroughSubject<Bool, Never>()
    private var estimatedTimeText: String = "예상 소요시간 --분 (--km)"

    private var selectedMenus: [MenuEntity] = []
    private let menuSelectedSubject = CurrentValueSubject<[MenuEntity], Never>([])
    private let checkoutTapSubject = PassthroughSubject<(store: StoreEntity, selectedMenus: [MenuEntity]), Never>()

    private let checkoutView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.shadowColor = AppColor.gray90.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let totalPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "0원"
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let selectedCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        return label
    }()

    private let checkoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("결제하기", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.title1
        button.backgroundColor = AppColor.gray45
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setRightBarButtons([likeButton])
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray15

        view.addSubview(collectionView)
        view.addSubview(checkoutView)

        checkoutView.addSubview(totalPriceLabel)
        checkoutView.addSubview(selectedCountLabel)
        checkoutView.addSubview(checkoutButton)

        collectionView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(checkoutView.snp.top)
        }

        checkoutView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(100)
            make.bottom.equalToSuperview()
        }

        totalPriceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.medium)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        selectedCountLabel.snp.makeConstraints { make in
            make.top.equalTo(totalPriceLabel.snp.bottom).offset(AppSpacing.tiny)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        checkoutButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.medium)
            make.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.width.equalTo(140)
            make.height.equalTo(52)
        }

        configureDataSource()
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        let input = ShopDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            storeLikeToggled: likeTapSubject.eraseToAnyPublisher(),
            menuSelected: menuSelectedSubject.eraseToAnyPublisher(),
            checkoutButtonTapped: checkoutTapSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.storeDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] store in
                self?.configure(with: store)
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)

        output.estimatedTimeText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeText in
                guard let self = self else { return }
                self.estimatedTimeText = timeText

                if let snapshot = self.dataSource?.snapshot() {
                    self.dataSource?.applySnapshotUsingReloadData(snapshot)
                }
            }
            .store(in: &cancellables)

        likeButton.tapPublisher
            .sink { [weak self] event in
                self?.likeTapSubject.send(event.newState)
            }
            .store(in: &cancellables)

        output.totalPrice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] totalPrice in
                self?.totalPriceLabel.text = totalPrice == 0 ? "0원" : "\(totalPrice.formatted())원"
            }
            .store(in: &cancellables)

        output.selectedCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.selectedCountLabel.text = count == 0 ? "" : "\(count)개 선택"
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(output.isCheckoutEnabled, output.isProcessingCheckout)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCheckoutEnabled, isProcessing in
                guard let self = self else { return }
                let shouldEnable = isCheckoutEnabled && !isProcessing
                self.checkoutButton.isEnabled = shouldEnable
                self.checkoutButton.backgroundColor = shouldEnable ? AppColor.deepSprout : AppColor.gray45
                self.checkoutButton.alpha = isProcessing ? 0.6 : 1.0
            }
            .store(in: &cancellables)

        checkoutButton.tapPublisher()
            .compactMap { [weak self] _ -> (StoreEntity, [MenuEntity])? in
                guard let self = self,
                      let store = self.currentStore,
                      !self.selectedMenus.isEmpty else {
                    return nil
                }
                return (store, self.selectedMenus)
            }
            .sink { [weak self] storeAndMenus in
                self?.checkoutTapSubject.send(storeAndMenus)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send()
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = self.dataSource?.sectionIdentifier(for: sectionIndex) else {
                return nil
            }

            switch section {
            case .imageCarousel:
                return self.createImageCarouselSection()
            case .storeInfo:
                return self.createStoreInfoSection()
            case .menu:
                return self.createMenuSection()
            }
        }
    }

    private func createImageCarouselSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(240)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: -24, trailing: 0)

        return section
    }

    private func createStoreInfoSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(400)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(400)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        return section
    }

    private func createMenuSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.screenMargin,
            bottom: AppSpacing.medium,
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

    private func configureDataSource() {
        let imageCarouselCellRegistration = UICollectionView.CellRegistration<ImageCarouselCell, StoreEntity> { cell, indexPath, store in
            cell.configure(with: store)
        }

        let storeInfoCellRegistration = UICollectionView.CellRegistration<StoreInfoCell, StoreEntity> { [weak self] cell, indexPath, store in
            guard let self = self else { return }
            cell.configure(with: store, estimatedTimeText: self.estimatedTimeText)
        }

        let menuCellRegistration = UICollectionView.CellRegistration<MenuCell, MenuEntity> { cell, indexPath, menu in
            cell.configure(with: menu)
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<MenuCategoryHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { headerView, elementKind, indexPath in
            guard let section = self.dataSource?.sectionIdentifier(for: indexPath.section),
                  case .menu(let category) = section else { return }
            headerView.configure(category: category)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .imageCarousel(let store):
                return collectionView.dequeueConfiguredReusableCell(
                    using: imageCarouselCellRegistration,
                    for: indexPath,
                    item: store
                )
            case .storeInfo(let store):
                return collectionView.dequeueConfiguredReusableCell(
                    using: storeInfoCellRegistration,
                    for: indexPath,
                    item: store
                )
            case .menu(let menu):
                return collectionView.dequeueConfiguredReusableCell(
                    using: menuCellRegistration,
                    for: indexPath,
                    item: menu
                )
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }

    private func configure(with store: StoreEntity) {
        currentStore = store
        likeButton.configure(storeId: store.storeId, isPicked: store.isPick)

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        snapshot.appendSections([.imageCarousel, .storeInfo])
        snapshot.appendItems([.imageCarousel(store)], toSection: .imageCarousel)
        snapshot.appendItems([.storeInfo(store)], toSection: .storeInfo)

        let menusByCategory = Dictionary(grouping: store.menuList, by: { $0.category })
        let sortedCategories = menusByCategory.keys.sorted()

        for category in sortedCategories {
            let section = Section.menu(category: category)
            snapshot.appendSections([section])

            if let menus = menusByCategory[category] {
                let menuItems = menus.map { Item.menu($0) }
                snapshot.appendItems(menuItems, toSection: section)
            }
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

}

extension ShopDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .menu(let menu):
            if menu.isSoldOut {
                showAlert(title: "품절", message: "품절된 상품은 선택할 수 없습니다.")
                return
            }

            if let index = selectedMenus.firstIndex(of: menu) {
                selectedMenus.remove(at: index)
                if let cell = collectionView.cellForItem(at: indexPath) as? MenuCell {
                    cell.setSelected(false)
                }
            } else {
                selectedMenus.append(menu)
                if let cell = collectionView.cellForItem(at: indexPath) as? MenuCell {
                    cell.setSelected(true)
                }
            }

            menuSelectedSubject.send(selectedMenus)

        default:
            break
        }
    }
}
