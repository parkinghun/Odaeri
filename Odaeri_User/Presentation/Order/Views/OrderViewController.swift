//
//  OrderViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class OrderViewController: BaseViewController<OrderViewModel> {
    private enum Section: Int, CaseIterable {
        case current
        case past
        
        var title: String {
            switch self {
            case .current:
                return "주문현황"
            case .past:
                return "이전 주문 내역"
            }
        }
    }
    
    private enum Item: Hashable {
        case currentStatus(id: String)
        case currentMenu(id: String)
        case past(id: String)
    }
    
    private let noticeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.brightSprout
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.deepSprout.cgColor
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let noticeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.brandCaption1
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.gray15
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private let emptyView = OrderEmptyView()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource?
    private var orderCache: [String: OrderListItemDisplay] = [:]
    private var currentOrders: [OrderListItemDisplay] = []
    private var pastOrders: [OrderListItemDisplay] = []
    private var lastTabBarInset: CGFloat = 0
    private var receiptCancellables: Set<AnyCancellable> = []
    private let priceTapSubject = PassthroughSubject<String, Never>()
    private let storeTapSubject = PassthroughSubject<String, Never>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
    }
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppColor.gray15
        
        view.addSubview(noticeContainerView)
        noticeContainerView.addSubview(noticeLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        
        noticeLabel.attributedText = makeNoticeText()
        
        noticeContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.xSmall)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.height.equalTo(40)
        }
        
        noticeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(noticeContainerView.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        emptyView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        configureDataSource()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewInsetsIfNeeded()
    }
    
    override func bind() {
        super.bind()
        
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = OrderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            priceTapped: priceTapSubject.eraseToAnyPublisher(),
            storeTapped: storeTapSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)
        
        output.currentOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.currentOrders = orders
                self?.updateCache(with: orders)
                self?.applySnapshot()
            }
            .store(in: &cancellables)
        
        output.pastOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.pastOrders = orders
                self?.updateCache(with: orders)
                self?.applySnapshot()
            }
            .store(in: &cancellables)
        
        output.isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.emptyView.isHidden = !isEmpty
                self?.collectionView.isHidden = isEmpty
            }
            .store(in: &cancellables)
        
        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)

        output.receiptOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.presentReceipt(order: order)
            }
            .store(in: &cancellables)
        
        viewDidLoadSubject.send(())
    }
    
    private func updateCache(with orders: [OrderListItemDisplay]) {
        for order in orders {
            orderCache[order.orderId] = order
        }
    }
    
    private func makeNoticeText() -> NSAttributedString {
        let text = "픽업을 하실 때는 주문번호를 꼭 말씀해주세요!"
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: AppFont.brandCaption1,
                .foregroundColor: AppColor.deepSprout
            ]
        )
        
        let highlightWords = ["픽업", "주문번호"]
        for word in highlightWords {
            let range = (text as NSString).range(of: word)
            if range.location != NSNotFound {
                attributed.addAttribute(.foregroundColor, value: AppColor.blackSprout, range: range)
            }
        }
        
        return attributed
    }
    
    private func configureDataSource() {
        let statusCellRegistration = UICollectionView.CellRegistration<OrderCurrentStatusCell, String> { [weak self] cell, _, orderId in
            guard let self = self,
                  let display = self.orderCache[orderId] else { return }
            cell.configure(with: display.currentStatus)
        }
        
        let menuCellRegistration = UICollectionView.CellRegistration<OrderCurrentMenuCell, String> { [weak self] cell, _, orderId in
            guard let self = self,
                  let display = self.orderCache[orderId] else { return }
            cell.configure(with: display.currentMenu)
            cell.onCellTapped = { [weak self] in
                self?.priceTapSubject.send(orderId)
            }
        }
        
        let pastCellRegistration = UICollectionView.CellRegistration<OrderPastCell, String> { [weak self] cell, _, orderId in
            guard let self = self,
                  let display = self.orderCache[orderId] else { return }
            cell.configure(with: display.past)
            cell.onPriceTapped = { [weak self] in
                self?.priceTapSubject.send(orderId)
            }
            cell.onStoreTapped = { [weak self] in
                self?.storeTapSubject.send(display.past.storeId)
            }
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<OrderSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { headerView, _, indexPath in
            guard let section = Section(rawValue: indexPath.section) else { return }
            let color: UIColor = section == .current ? AppColor.gray60 : AppColor.gray45
            headerView.configure(title: section.title, textColor: color)
        }
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .currentStatus(let id):
                return collectionView.dequeueConfiguredReusableCell(using: statusCellRegistration, for: indexPath, item: id)
            case .currentMenu(let id):
                return collectionView.dequeueConfiguredReusableCell(using: menuCellRegistration, for: indexPath, item: id)
            case .past(let id):
                return collectionView.dequeueConfiguredReusableCell(using: pastCellRegistration, for: indexPath, item: id)
            }
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        
        if !currentOrders.isEmpty {
            snapshot.appendSections([.current])
            let items = currentOrders.flatMap { order -> [Item] in
                return [.currentStatus(id: order.orderId), .currentMenu(id: order.orderId)]
            }
            snapshot.appendItems(items, toSection: .current)
        }
        
        if !pastOrders.isEmpty {
            snapshot.appendSections([.past])
            let items = pastOrders.map { Item.past(id: $0.orderId) }
            snapshot.appendItems(items, toSection: .past)
        }
        
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let sectionLayout = NSCollectionLayoutSection(group: group)
            sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: AppSpacing.screenMargin,
                bottom: AppSpacing.large,
                trailing: AppSpacing.screenMargin
            )
            sectionLayout.interGroupSpacing = AppSpacing.small
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(48)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            header.contentInsets = .zero
            sectionLayout.boundarySupplementaryItems = [header]
            
            let decorationKind: String
            switch section {
            case .current:
                decorationKind = OrderSectionBackgroundCurrentView.kind
            case .past:
                decorationKind = OrderSectionBackgroundPastView.kind
            }
            sectionLayout.decorationItems = [
                NSCollectionLayoutDecorationItem.background(elementKind: decorationKind)
            ]
            
            return sectionLayout
        }
        let config = UICollectionViewCompositionalLayoutConfiguration()
        layout.configuration = config
        layout.register(
            OrderSectionBackgroundCurrentView.self,
            forDecorationViewOfKind: OrderSectionBackgroundCurrentView.kind
        )
        layout.register(
            OrderSectionBackgroundPastView.self,
            forDecorationViewOfKind: OrderSectionBackgroundPastView.kind
        )
        return layout
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

    private func presentReceipt(order: OrderListItemEntity) {
        let viewController = OrderReceiptViewController(order: order)
        viewController.onStoreTapped = { [weak self] storeId in
            guard let self else { return }
            viewController.dismiss(animated: true) { [weak self] in
                self?.storeTapSubject.send(storeId)
            }
        }
        receiptCancellables.removeAll()
        viewController.reviewActionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak viewController] order in
                guard let self else { return }
                viewController?.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    let mode: ReviewWriteMode = order.review == nil ? .create(order: order) : .edit(order: order)
                    self.viewModel.coordinator?.showReviewWrite(mode: mode)
                }
            }
            .store(in: &receiptCancellables)
        present(viewController, animated: true)
    }
}
