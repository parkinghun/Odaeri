//
//  ShopDetailViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import Foundation
import Combine
import CoreLocation

final class ShopDetailViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: HomeCoordinator?

    private let storeRepository: StoreRepository
    private let orderRepository: OrderRepository
    private let locationManager: LocationManager
    private let storeId: String
    private let errorSubject = PassthroughSubject<String, Never>()
    private let isProcessingCheckoutSubject = CurrentValueSubject<Bool, Never>(false)

    init(
        storeId: String,
        storeRepository: StoreRepository = StoreRepositoryImpl(),
        orderRepository: OrderRepository = OrderRepositoryImpl(),
        locationManager: LocationManager = .shared
    ) {
        self.storeId = storeId
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
        self.locationManager = locationManager
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let storeLikeToggled: AnyPublisher<Bool, Never>
        let menuSelected: AnyPublisher<[MenuEntity], Never>
        let checkoutButtonTapped: AnyPublisher<(store: StoreEntity, selectedMenus: [MenuEntity]), Never>
    }

    struct Output {
        let storeDetail: AnyPublisher<StoreEntity, Never>
        let currentLocation: AnyPublisher<CLLocation?, Never>
        let estimatedTimeText: AnyPublisher<String, Never>
        let totalPrice: AnyPublisher<Int, Never>
        let selectedCount: AnyPublisher<Int, Never>
        let isCheckoutEnabled: AnyPublisher<Bool, Never>
        let isProcessingCheckout: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let storeDetailSubject = PassthroughSubject<StoreEntity, Never>()
        let currentLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)

        // 위치 업데이트 구독
        locationManager.locationSubject
            .compactMap { $0 }
            .sink { location in
                print("📍 뷰모델 위치 수신: \(location.coordinate)")
                currentLocationSubject.send(location)
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.locationManager.checkPermissionAndStartUpdating()
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<StoreEntity, Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }

                return self.storeRepository.fetchStoreDetail(storeId: self.storeId)
                    .catch { [weak self] error -> AnyPublisher<StoreEntity, Never> in
                        self?.errorSubject.send(error.errorDescription)
                        return Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { store in
                storeDetailSubject.send(store)
            }
            .store(in: &cancellables)

        input.storeLikeToggled
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .flatMap { [weak self] newStatus -> AnyPublisher<Void, Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }

                return self.storeRepository.toggleLike(storeId: self.storeId, status: newStatus)
                    .catch { [weak self] error -> AnyPublisher<Void, Never> in
                        self?.errorSubject.send(error.errorDescription)
                        return Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { _ in }
            .store(in: &cancellables)

        let totalPrice = input.menuSelected
            .map { menus in
                menus.reduce(0) { sum, menu in
                    sum + menu.priceValue
                }
            }
            .eraseToAnyPublisher()

        let selectedCount = input.menuSelected
            .map { $0.count }
            .eraseToAnyPublisher()

        let isCheckoutEnabled = input.menuSelected
            .map { !$0.isEmpty }
            .eraseToAnyPublisher()

        input.checkoutButtonTapped
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .filter { [weak self] _ in
                guard let self = self else { return false }
                return !self.isProcessingCheckoutSubject.value
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isProcessingCheckoutSubject.send(true)
            })
            .flatMap { [weak self] store, selectedMenus -> AnyPublisher<(OrderCreateEntity, StoreEntity, Int), Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }

                let totalPrice = selectedMenus.reduce(0) { sum, menu in
                    return sum + menu.priceValue
                }

                let orderMenuList = selectedMenus.map { menu in
                    OrderMenuItem(menuId: menu.menuId, quantity: 1)
                }

                return self.orderRepository.createOrder(
                    storeId: store.storeId,
                    orderMenuList: orderMenuList,
                    totalPrice: totalPrice
                )
                .map { orderEntity in
                    return (orderEntity, store, totalPrice)
                }
                .catch { [weak self] error -> AnyPublisher<(OrderCreateEntity, StoreEntity, Int), Never> in
                    self?.errorSubject.send("주문 생성 실패: \(error.errorDescription)")
                    self?.isProcessingCheckoutSubject.send(false)
                    return Empty().eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] orderEntity, store, totalPrice in
                guard let self = self else { return }

                let paymentRequest = PaymentRequest(
                    orderCode: orderEntity.orderCode,
                    amount: totalPrice,
                    storeName: store.name
                )

                self.coordinator?.showPayment(paymentRequest: paymentRequest)
                self.isProcessingCheckoutSubject.send(false)
            }
            .store(in: &cancellables)

        let estimatedTimeText = Publishers.CombineLatest(
            storeDetailSubject,
            currentLocationSubject
        )
        .map { store, currentLocation -> String in
            guard let currentLocation = currentLocation else {
                return "예상 소요시간 --분 (--km)"
            }

            let distance = RouteManager.shared.calculateDistance(
                from: currentLocation.coordinate,
                to: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
            )
            let estimatedTime = RouteManager.shared.calculateEstimatedTime(distanceInKm: distance)
            let formattedTime = RouteManager.shared.formatTime(estimatedTime)

            return "예상 소요시간 \(formattedTime) (\(String(format: "%.1f", distance))km)"
        }
        .eraseToAnyPublisher()

        return Output(
            storeDetail: storeDetailSubject.eraseToAnyPublisher(),
            currentLocation: currentLocationSubject.eraseToAnyPublisher(),
            estimatedTimeText: estimatedTimeText,
            totalPrice: totalPrice,
            selectedCount: selectedCount,
            isCheckoutEnabled: isCheckoutEnabled,
            isProcessingCheckout: isProcessingCheckoutSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
}
