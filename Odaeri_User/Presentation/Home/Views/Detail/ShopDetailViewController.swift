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
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(AppImage.chevron, for: .normal)
        button.tintColor = AppColor.gray0
        button.backgroundColor = AppColor.gray75.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let likeButton = LikeButton()

    private var currentStore: StoreEntity?
    private let likeTapSubject = PassthroughSubject<Bool, Never>()

    private var selectedMenus: [MenuEntity] = []

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
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (tabBarController as? CustomTabBarController)?.setTabBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? CustomTabBarController)?.setTabBarHidden(false, animated: false)
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray15

        view.addSubview(collectionView)
        view.addSubview(checkoutView)
        view.addSubview(backButton)
        view.addSubview(likeButton)

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

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            make.width.height.equalTo(40)
        }

        likeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            make.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.width.height.equalTo(40)
        }

        configureDataSource()
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        let input = ShopDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            storeLikeToggled: likeTapSubject.eraseToAnyPublisher()
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

        backButton.tapPublisher()
            .sink { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)

        likeButton.tapPublisher
            .sink { [weak self] event in
                self?.likeTapSubject.send(event.newState)
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

        let storeInfoCellRegistration = UICollectionView.CellRegistration<StoreInfoCell, StoreEntity> { cell, indexPath, store in
            cell.configure(with: store)
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

    private func updateCheckoutView() {
        let totalPrice = selectedMenus.reduce(0) { sum, menu in
            return sum + menu.priceValue
        }

        totalPriceLabel.text = totalPrice == 0 ? "0원" : "\(totalPrice.formatted())원"
        selectedCountLabel.text = selectedMenus.isEmpty ? "" : "\(selectedMenus.count)개 선택"

        if selectedMenus.isEmpty {
            checkoutButton.isEnabled = false
            checkoutButton.backgroundColor = AppColor.gray45
        } else {
            checkoutButton.isEnabled = true
            checkoutButton.backgroundColor = AppColor.deepSprout
        }
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

            updateCheckoutView()

        default:
            break
        }
    }
}

// MARK: - ImageCarouselCell

final class ImageCarouselCell: UICollectionViewCell {
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColor.gray30
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StoreImageCell.self, forCellWithReuseIdentifier: "StoreImageCell")
        return collectionView
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = AppColor.gray0
        control.pageIndicatorTintColor = AppColor.gray60
        control.isUserInteractionEnabled = false
        return control
    }()

    private var storeImages: [String] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageCollectionView)
        contentView.addSubview(pageControl)

        imageCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(AppSpacing.xxxLarge)
        }
    }

    func configure(with store: StoreEntity) {
        storeImages = store.storeImageUrls
        pageControl.numberOfPages = storeImages.count
        pageControl.currentPage = 0
        imageCollectionView.reloadData()
    }
}

extension ImageCarouselCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storeImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StoreImageCell", for: indexPath) as! StoreImageCell
        cell.configure(with: storeImages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = pageIndex
    }
}

// MARK: - StoreImageCell

final class StoreImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.resetImage()
    }

    func configure(with urlString: String?) {
        imageView.setImage(url: urlString)
    }
}

// MARK: - StoreInfoCell

final class StoreInfoCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let picchelinImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.pickchelin
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let likeIconLabelView = IconLabelView(
        icon: AppImage.likeFill,
        iconColor: AppColor.brightForsythia,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private let rateIconLabelView = IconLabelView(
        icon: AppImage.starFill,
        iconColor: AppColor.brightForsythia,
        font: AppFont.body1Bold,
        textColor: AppColor.gray90
    )

    private let rateCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Regular
        label.textColor = AppColor.gray60
        return label
    }()

    private let orderIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.bike
        view.tintColor = AppColor.gray45
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let orderCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3
        label.textColor = AppColor.gray45
        return label
    }()

    private let detailInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let addressInfoRow = StoreInfoRowView()
    private let timeInfoRow = StoreInfoRowView()
    private let parkingInfoRow = StoreInfoRowView()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [addressInfoRow, timeInfoRow, parkingInfoRow])
        stackView.spacing = 13.5
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let estimatedTimeView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.brightSprout
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let estimatedTimeIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.run
        view.tintColor = AppColor.gray75
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let estimatedTimeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Regular
        label.textColor = AppColor.gray75
        return label
    }()

    private let findRouteButton: UIButton = {
        let button = UIButton()
        button.setTitle("길찾기", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.title1
        button.backgroundColor = AppColor.deepSprout
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)

        containerView.addSubview(nameLabel)
        containerView.addSubview(picchelinImageView)
        containerView.addSubview(likeIconLabelView)
        containerView.addSubview(rateIconLabelView)
        containerView.addSubview(rateCountLabel)
        containerView.addSubview(orderIconImageView)
        containerView.addSubview(orderCountLabel)
        containerView.addSubview(detailInfoView)
        containerView.addSubview(estimatedTimeView)
        containerView.addSubview(findRouteButton)

        detailInfoView.addSubview(infoStackView)

        estimatedTimeView.addSubview(estimatedTimeIconImageView)
        estimatedTimeView.addSubview(estimatedTimeLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.xxxLarge)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        picchelinImageView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(AppSpacing.small)
            make.centerY.equalTo(nameLabel)
            make.width.equalTo(65)
            make.height.equalTo(34)
        }

        likeIconLabelView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppSpacing.medium)
            make.leading.equalToSuperview().offset(AppSpacing.screenMargin)
        }

        rateIconLabelView.snp.makeConstraints { make in
            make.centerY.equalTo(likeIconLabelView)
            make.leading.equalTo(likeIconLabelView.snp.trailing).offset(AppSpacing.medium)
        }

        rateCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(rateIconLabelView.snp.trailing).offset(AppSpacing.tiny)
            make.centerY.equalTo(rateIconLabelView)
        }

        orderIconImageView.snp.makeConstraints { make in
            make.trailing.equalTo(orderCountLabel.snp.leading).offset(-AppSpacing.tiny)
            make.centerY.equalTo(rateIconLabelView)
            make.size.equalTo(20)
        }

        orderCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(orderIconImageView)
            make.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        detailInfoView.snp.makeConstraints { make in
            make.top.equalTo(likeIconLabelView.snp.bottom).offset(AppSpacing.medium)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        infoStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(AppSpacing.large)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        estimatedTimeView.snp.makeConstraints { make in
            make.top.equalTo(detailInfoView.snp.bottom).offset(AppSpacing.medium)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        estimatedTimeIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        estimatedTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(estimatedTimeIconImageView.snp.trailing).offset(AppSpacing.tiny)
            make.trailing.equalToSuperview().inset(AppSpacing.medium)
            make.top.bottom.equalToSuperview().inset(AppSpacing.small)
        }

        findRouteButton.snp.makeConstraints { make in
            make.top.equalTo(estimatedTimeView.snp.bottom).offset(AppSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(AppSpacing.large)
        }
    }

    func configure(with store: StoreEntity) {
        nameLabel.text = store.name
        picchelinImageView.isHidden = !store.isPicchelin

        likeIconLabelView.updateText("\(store.pickCount)개")
        rateIconLabelView.updateText(store.rate)
        rateCountLabel.text = "(\(store.totalReviewCount))"
        orderCountLabel.text = "누적 주문 135회"

        addressInfoRow.configure(info: .address, text: store.address)
        timeInfoRow.configure(info: .time, text: "매일 \(store.open) ~ \(store.close)")
        parkingInfoRow.configure(info: .parking, text: store.parkingGuide)

        estimatedTimeLabel.text = "예상 소요시간 \(store.estimatedPickupTime)분 (3.2km)"
    }
}

// MARK: - StoreInfoRowView

final class StoreInfoRowView: UIView {
    enum Info: String {
        case address = "가게주소"
        case time = "영업시간"
        case parking = "주차여부"

        var icon: UIImage {
            switch self {
            case .address: AppImage.distance
            case .time: AppImage.time
            case .parking: AppImage.parking
            }
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(iconImageView)
        addSubview(infoLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(AppSpacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        infoLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(AppSpacing.xSmall)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func configure(info: Info, text: String) {
        titleLabel.text = info.rawValue
        iconImageView.image = info.icon
        iconImageView.tintColor = AppColor.deepSprout
        infoLabel.text = text
    }
}
