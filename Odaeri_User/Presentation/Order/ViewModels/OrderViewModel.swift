//
//  OrderViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import Foundation
import Combine
import UIKit

final class OrderViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: OrderCoordinator?

    private let orderRepository: OrderRepository
    private let errorSubject = PassthroughSubject<String, Never>()
    private var orderEntityCache: [String: OrderListItemEntity] = [:]

    init(orderRepository: OrderRepository = OrderRepositoryImpl()) {
        self.orderRepository = orderRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let priceTapped: AnyPublisher<String, Never>
        let storeTapped: AnyPublisher<String, Never>
        let reviewTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let currentOrders: AnyPublisher<[OrderListItemDisplay], Never>
        let pastOrders: AnyPublisher<[OrderListItemDisplay], Never>
        let isEmpty: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let receiptOrder: AnyPublisher<OrderListItemEntity, Never>
    }

    func transform(input: Input) -> Output {
        let currentOrdersSubject = CurrentValueSubject<[OrderListItemDisplay], Never>([])
        let pastOrdersSubject = CurrentValueSubject<[OrderListItemDisplay], Never>([])
        let isEmptySubject = CurrentValueSubject<Bool, Never>(true)
        let receiptOrderSubject = PassthroughSubject<OrderListItemEntity, Never>()

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<[OrderListItemEntity], Never> in
                guard let self = self else { return Just([]).eraseToAnyPublisher() }
                return self.orderRepository.getOrderList(status: nil)
                    .catch { [weak self] error -> AnyPublisher<[OrderListItemEntity], Never> in
                        self?.errorSubject.send(error.errorDescription)
                        return Just([]).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { orders in
                self.orderEntityCache = Dictionary(uniqueKeysWithValues: orders.map { ($0.orderId, $0) })
                let current = orders.filter { $0.currentOrderStatus != .pickedUp }
                let past = orders.filter { $0.currentOrderStatus == .pickedUp }
                let currentDisplay = current.map { self.makeDisplay(from: $0) }
                let pastDisplay = past.map { self.makeDisplay(from: $0) }
                currentOrdersSubject.send(currentDisplay)
                pastOrdersSubject.send(pastDisplay)
                isEmptySubject.send(currentDisplay.isEmpty && pastDisplay.isEmpty)
            }
            .store(in: &cancellables)

        input.priceTapped
            .compactMap { [weak self] orderId in
                self?.orderEntityCache[orderId]
            }
            .sink { order in
                receiptOrderSubject.send(order)
            }
            .store(in: &cancellables)

        input.storeTapped
            .sink { [weak self] storeId in
                self?.coordinator?.showStoreDetail(storeId: storeId)
            }
            .store(in: &cancellables)

        input.reviewTapped
            .compactMap { [weak self] orderId in
                self?.orderEntityCache[orderId]
            }
            .sink { [weak self] order in
                let mode: ReviewWriteMode = order.review == nil ? .create(order: order) : .edit(order: order)
                self?.coordinator?.showReviewWrite(mode: mode)
            }
            .store(in: &cancellables)

        return Output(
            currentOrders: currentOrdersSubject.eraseToAnyPublisher(),
            pastOrders: pastOrdersSubject.eraseToAnyPublisher(),
            isEmpty: isEmptySubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            receiptOrder: receiptOrderSubject.eraseToAnyPublisher()
        )
    }
}

struct OrderListItemDisplay {
    let orderId: String
    let orderEntity: OrderListItemEntity
    let currentStatus: OrderCurrentStatusDisplay
    let currentMenu: OrderCurrentMenuDisplay
    let past: OrderPastDisplay
}

struct OrderCurrentStatusDisplay {
    let orderCodeTitle: String
    let orderCodeValue: String
    let storeName: String
    let orderDateText: String
    let categoryImage: UIImage?
    let statusSteps: [OrderStatusStepDisplay]
}

struct OrderCurrentMenuDisplay {
    let menuRows: [OrderMenuRowDisplay]
    let totalQuantityText: String
    let totalPriceText: String
}

struct OrderMenuRowDisplay {
    let imageUrl: String
    let name: String
    let priceText: String
    let quantityText: String
}

struct OrderPastDisplay {
    let storeId: String
    let storeName: String
    let orderCodeText: String
    let orderDateText: String
    let menuSummaryText: String
    let priceText: String
    let storeImageUrl: String?
    let review: OrderReviewDisplay?
}

struct OrderReviewDisplay {
    let ratingText: String
}

struct OrderStatusStepDisplay {
    let title: String
    let timeText: String?
    let isActive: Bool
    let showsConnector: Bool
    let isConnectorActive: Bool
}

private extension OrderViewModel {
    func makeDisplay(from order: OrderListItemEntity) -> OrderListItemDisplay {
        let statusSteps = makeStatusSteps(order: order)
        let statusDisplay = OrderCurrentStatusDisplay(
            orderCodeTitle: "주문번호",
            orderCodeValue: order.orderCode,
            storeName: order.store.name,
            orderDateText: currentOrderDateText(for: order),
            categoryImage: categoryImage(for: order.store.category),
            statusSteps: statusSteps
        )

        let menuRows = order.orderMenuList.map { menu in
            OrderMenuRowDisplay(
                imageUrl: menu.menu.menuImageUrl,
                name: menu.menu.name,
                priceText: formattedPrice(menu.menu.price),
                quantityText: "\(menu.quantity)EA"
            )
        }

        let totalQuantity = order.orderMenuList.reduce(0) { $0 + $1.quantity }
        let menuDisplay = OrderCurrentMenuDisplay(
            menuRows: menuRows,
            totalQuantityText: "\(totalQuantity)EA",
            totalPriceText: formattedPrice(order.totalPrice)
        )

        let pastDisplay = OrderPastDisplay(
            storeId: order.store.id,
            storeName: order.store.name,
            orderCodeText: order.orderCode,
            orderDateText: pastOrderDateText(for: order),
            menuSummaryText: menuSummaryText(for: order),
            priceText: formattedPrice(order.totalPrice),
            storeImageUrl: order.store.storeImageUrls.first,
            review: reviewDisplay(for: order)
        )

        return OrderListItemDisplay(
            orderId: order.orderId,
            orderEntity: order,
            currentStatus: statusDisplay,
            currentMenu: menuDisplay,
            past: pastDisplay
        )
    }

    func reviewDisplay(for order: OrderListItemEntity) -> OrderReviewDisplay? {
        guard let review = order.review else { return nil }
        return OrderReviewDisplay(ratingText: "\(review.rating).0")
    }

    func menuSummaryText(for order: OrderListItemEntity) -> String {
        guard let first = order.orderMenuList.first else { return "메뉴 없음" }
        if order.orderMenuList.count > 1 {
            return "\(first.menu.name) 외 \(order.orderMenuList.count - 1)건"
        }
        return first.menu.name
    }

    func formattedPrice(_ value: Int) -> String {
        return "\(value.formatted())원"
    }

    func currentOrderDateText(for order: OrderListItemEntity) -> String {
        if let createdAt = order.createdAt {
            return DateFormatter.fullDisplay.string(from: createdAt)
        }
        return "주문 시간 미확인"
    }

    func pastOrderDateText(for order: OrderListItemEntity) -> String {
        if let paidAt = order.paidAt {
            return DateFormatter.dotDisplay.string(from: paidAt)
        } 
        return "결제일 미확인"
    }

    func categoryImage(for category: String) -> UIImage? {
        switch category.lowercased() {
        case "bakery":
            return Category.bakery.image
        case "coffee":
            return Category.coffee.image
        case "dessert":
            return Category.dessert.image
        case "fastfood":
            return Category.fastFood.image
        default:
            return Category.more.image
        }
    }

    func makeStatusSteps(order: OrderListItemEntity) -> [OrderStatusStepDisplay] {
        let statuses: [OrderStatusEntity] = [
            .pendingApproval, .approved, .inProgress, .readyForPickup, .pickedUp
        ]
        return statuses.enumerated().map { index, status in
            let isActive = isActiveStatus(status: status, order: order)
            let timeText = statusTimeText(for: status, order: order)
            let showsConnector = index < statuses.count - 1
            let isConnectorActive = isConnectorActive(at: index, order: order, statuses: statuses)
            return OrderStatusStepDisplay(
                title: status.description,
                timeText: timeText,
                isActive: isActive,
                showsConnector: showsConnector,
                isConnectorActive: isConnectorActive
            )
        }
    }

    func isActiveStatus(status: OrderStatusEntity, order: OrderListItemEntity) -> Bool {
        let orderList: [OrderStatusEntity] = [.pendingApproval, .approved, .inProgress, .readyForPickup, .pickedUp]
        guard let currentIndex = orderList.firstIndex(of: order.currentOrderStatus),
              let statusIndex = orderList.firstIndex(of: status) else {
            return false
        }
        return statusIndex <= currentIndex
    }

    func isConnectorActive(at index: Int, order: OrderListItemEntity, statuses: [OrderStatusEntity]) -> Bool {
        guard let currentIndex = statuses.firstIndex(of: order.currentOrderStatus) else { return false }
        return index < currentIndex
    }

    func statusTimeText(for status: OrderStatusEntity, order: OrderListItemEntity) -> String? {
        guard let timeline = order.orderStatusTimeline.first(where: { $0.status == status }),
              timeline.completed,
              let changedAt = timeline.changedAt else {
            return nil
        }
        return DateFormatter.timeDisplay.string(from: changedAt)
    }
}
