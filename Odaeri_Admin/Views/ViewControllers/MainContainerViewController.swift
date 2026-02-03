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
    private let sideListViewController = IntegratedOrderListViewController()
    private let detailViewController = AdminOrderDetailViewController()

    private let sideListView = UIView()
    private let detailContainerView = UIView()
    private var mockOrderEntities: [OrderListItemEntity] = []
    private var selectedOrderCode: String?
    private var cancellables = Set<AnyCancellable>()

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
            self?.selectOrder(code: order.orderCode)
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
        let orders = mapOrders(from: entities)
        sideListViewController.updateOrders(orders)
        if let firstEntity = entities.first {
            selectedOrderCode = firstEntity.orderCode
            detailViewController.configure(order: firstEntity)
        }
    }

    private func selectOrder(code: String) {
        selectedOrderCode = code
        guard let entity = mockOrderEntities.first(where: { $0.orderCode == code }) else { return }
        detailViewController.configure(order: entity)
    }

    private func applyStatusUpdate(_ nextStatus: OrderStatusEntity) {
        guard let selectedOrderCode else { return }
        guard let index = mockOrderEntities.firstIndex(where: { $0.orderCode == selectedOrderCode }) else { return }

        let updated = mockOrderEntities[index].updatingStatus(nextStatus)
        mockOrderEntities[index] = updated

        sideListViewController.updateOrders(mapOrders(from: mockOrderEntities))
        detailViewController.configure(order: updated)
    }

    private func mapOrders(from entities: [OrderListItemEntity]) -> [Order] {
        entities.map { entity in
            let mappedStatus: OrderStatus
            switch entity.currentOrderStatus {
            case .pendingApproval, .approved:
                mappedStatus = .pending
            case .inProgress:
                mappedStatus = .cooking
            case .readyForPickup, .pickedUp:
                mappedStatus = .completed
            }

            let menus = entity.orderMenuList.map {
                Menu(name: $0.menu.name, price: $0.menu.price, quantity: $0.quantity, imageUrl: $0.menu.menuImageUrl)
            }

            return Order(
                orderCode: entity.orderCode,
                totalPrice: entity.totalPrice,
                status: mappedStatus,
                orderTime: entity.createdAt ?? Date(),
                storeName: entity.store.name,
                menus: menus
            )
        }
    }
}
