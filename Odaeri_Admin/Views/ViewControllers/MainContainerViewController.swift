//
//  MainContainerViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit
import Combine

final class MainContainerViewController: UIViewController {
    private let sideListViewController: IntegratedOrderListViewController
    private let detailViewController = AdminOrderDetailViewController()

    private let sideListView = UIView()
    private let detailContainerView = UIView()
    private var mockOrderEntities: [OrderListItemEntity] = []
    private var selectedOrderCode: String?
    private var cancellables = Set<AnyCancellable>()

    init(initialFilter: IntegratedOrderListViewController.InitialFilter = .processing) {
        self.sideListViewController = IntegratedOrderListViewController(initialFilter: initialFilter)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        loadMockOrders()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6

        view.addSubview(sideListView)
        view.addSubview(detailContainerView)

        sideListView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalTo(320)
        }

        detailContainerView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(sideListView.snp.trailing)
        }

        addChild(sideListViewController)
        sideListView.addSubview(sideListViewController.view)
        sideListViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        sideListViewController.didMove(toParent: self)

        addChild(detailViewController)
        detailContainerView.addSubview(detailViewController.view)
        detailViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        detailViewController.didMove(toParent: self)
    }

    private func bind() {
        sideListViewController.onSelectOrder = { [weak self] order in
            self?.selectOrder(order)
        }

        detailViewController.updateStatusPublisher
            .sink { [weak self] nextStatus in
                self?.applyStatusUpdate(nextStatus)
            }
            .store(in: &cancellables)
    }

    private func loadMockOrders() {
        let entities = AdminOrderMockFactory.makeOrders()
        mockOrderEntities = entities
        sideListViewController.updateOrders(entities)
        if let firstEntity = entities.first {
            selectedOrderCode = firstEntity.orderCode
            detailViewController.configure(order: firstEntity)
        }
    }

    private func selectOrder(_ order: OrderListItemEntity) {
        selectedOrderCode = order.orderCode
        guard let entity = mockOrderEntities.first(where: { $0.orderCode == order.orderCode }) else { return }
        detailViewController.configure(order: entity)
    }

    private func applyStatusUpdate(_ nextStatus: OrderStatusEntity) {
        guard let selectedOrderCode else { return }
        guard let index = mockOrderEntities.firstIndex(where: { $0.orderCode == selectedOrderCode }) else { return }

        let updated = mockOrderEntities[index].updatingStatus(nextStatus)
        mockOrderEntities[index] = updated

        sideListViewController.updateOrders(mockOrderEntities)
        detailViewController.configure(order: updated)
    }
}
