//
//  AdminDashboardSplitViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import Combine
import SnapKit

final class AdminDashboardSplitViewController: UIViewController {
    private let storeManagementViewModel = AdminStoreManagementViewModel()
    private let listContainerViewController: AdminOrdersListContainerViewController
    private let detailContainerViewController: AdminDashboardDetailContainerViewController
    private let dividerView = UIView()
    private var storeManagementCancellables = Set<AnyCancellable>()
    private var storeManagementStore: StoreEntity?
    private var storeManagementSelectedItem: AdminStoreManagementItem = .storeInfo

    var inProgressSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        listContainerViewController.inProgressSortPublisher
    }

    var completedSortPublisher: AnyPublisher<AdminSortOrder, Never> {
        listContainerViewController.completedSortPublisher
    }

    var selectionPublisher: AnyPublisher<OrderListItemEntity?, Never> {
        listContainerViewController.selectionPublisher
    }

    var statusUpdatePublisher: AnyPublisher<AdminOrderStatusUpdate, Never> {
        let listUpdates = listContainerViewController.statusUpdatePublisher
        let detailUpdates = detailContainerViewController.statusUpdatePublisher
        return Publishers.Merge(listUpdates, detailUpdates).eraseToAnyPublisher()
    }

    init() {
        let storeManagementList = AdminStoreManagementListViewController()
        let storeManagementDetail = AdminStoreManagementDetailViewController()
        self.listContainerViewController = AdminOrdersListContainerViewController(
            storeManagementViewController: storeManagementList
        )
        self.detailContainerViewController = AdminDashboardDetailContainerViewController(
            storeManagementViewController: storeManagementDetail
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindStoreManagement()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        dividerView.backgroundColor = AppColor.gray30

        addChild(listContainerViewController)
        addChild(detailContainerViewController)

        view.addSubview(listContainerViewController.view)
        view.addSubview(dividerView)
        view.addSubview(detailContainerViewController.view)

        listContainerViewController.view.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(Layout.listWidth)
        }

        dividerView.snp.makeConstraints {
            $0.leading.equalTo(listContainerViewController.view.snp.trailing)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(Layout.dividerWidth)
        }

        detailContainerViewController.view.snp.makeConstraints {
            $0.leading.equalTo(dividerView.snp.trailing)
            $0.top.bottom.trailing.equalToSuperview()
        }

        listContainerViewController.didMove(toParent: self)
        detailContainerViewController.didMove(toParent: self)
    }

    private func bindStoreManagement() {
        let input = AdminStoreManagementViewModel.Input(
            viewDidLoad: listContainerViewController.storeManagementViewDidLoadPublisher,
            selectItem: listContainerViewController.storeManagementSelectionPublisher,
            saveStore: detailContainerViewController.storeManagementSaveStorePublisher,
            saveMenu: detailContainerViewController.storeManagementSaveMenuPublisher
        )
        let output = storeManagementViewModel.transform(input: input)

        output.store
            .receive(on: DispatchQueue.main)
            .sink { [weak self] store in
                guard let self else { return }
                self.storeManagementStore = store
                self.listContainerViewController.updateStoreManagementStore(store)
                self.detailContainerViewController.updateStoreManagement(store: store, selectedItem: self.storeManagementSelectedItem)
            }
            .store(in: &storeManagementCancellables)

        output.selectedItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let self else { return }
                self.storeManagementSelectedItem = item
                self.listContainerViewController.updateStoreManagementSelection(item)
                self.detailContainerViewController.updateStoreManagement(store: self.storeManagementStore, selectedItem: item)
            }
            .store(in: &storeManagementCancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.detailContainerViewController.showError(message: message)
            }
            .store(in: &storeManagementCancellables)
    }

    func show(tab: AdminDashboardTab) {
        listContainerViewController.show(tab: tab)
        detailContainerViewController.show(tab: tab)
    }

    func updateInProgressNew(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateInProgressNew(orders)
    }

    func updateInProgressActive(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateInProgressActive(orders)
    }

    func updateCompleted(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateCompleted(orders)
    }

    func updateOrderLookup(_ orders: [OrderListItemEntity]) {
        listContainerViewController.updateOrderLookup(orders)
    }

    func updateOrder(_ order: OrderListItemEntity?) {
        detailContainerViewController.updateOrder(order)
    }

    func updateSalesOrders(_ orders: [OrderListItemEntity]) {
        detailContainerViewController.updateSalesOrders(orders)
    }

    func showError(message: String) {
        detailContainerViewController.showError(message: message)
    }

    func reloadStoreManagement() {
        storeManagementViewModel.reloadStore()
    }
}

private enum Layout {
    static let listWidth: CGFloat = 380
    static let dividerWidth: CGFloat = 1
}
