//
//  StoreSearchViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation
import Combine
import CoreLocation

struct RecentStoreItem {
    let store: OrderStoreInfoEntity
    let paidAt: Date?
}

struct StoreSearchListItem {
    let store: StoreEntity
    let distanceText: String?
}

enum StoreSearchViewState {
    case initial(String)
    case searching
    case results([StoreSearchListItem])
    case nearbyStores([StoreSearchListItem])
    case empty(String)
    case recentStores([RecentStoreItem])

    var shouldShowTableView: Bool {
        switch self {
        case .results, .recentStores, .nearbyStores:
            return true
        case .initial, .searching, .empty:
            return false
        }
    }

    var shouldShowEmptyLabel: Bool {
        switch self {
        case .initial, .empty:
            return true
        case .searching, .results, .recentStores, .nearbyStores:
            return false
        }
    }

    var emptyMessage: String? {
        switch self {
        case .initial(let message), .empty(let message):
            return message
        case .searching, .results, .recentStores, .nearbyStores:
            return nil
        }
    }

    var sectionTitle: String? {
        switch self {
        case .results:
            return "검색 결과"
        case .nearbyStores:
            return "주변 매장"
        case .recentStores:
            return "최근 방문/결제한 가게"
        case .initial, .searching, .empty:
            return nil
        }
    }
}

final class StoreSearchViewModel: BaseViewModel, ViewModelType {
    private let viewType: StoreSearchViewType
    let initialSearchQuery: String?
    private let storeRepository: StoreRepository
    private let orderRepository: OrderRepository
    private let locationManager: LocationManaging?
    private let routeManager: RouteManaging?

    init(
        viewType: StoreSearchViewType,
        initialSearchQuery: String? = nil,
        storeRepository: StoreRepository,
        orderRepository: OrderRepository,
        locationManager: LocationManaging? = nil,
        routeManager: RouteManaging? = nil
    ) {
        self.viewType = viewType
        self.initialSearchQuery = initialSearchQuery
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
        self.locationManager = locationManager
        self.routeManager = routeManager
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let searchButtonTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let viewState: AnyPublisher<StoreSearchViewState, Never>
        let searchResults: AnyPublisher<[StoreSearchListItem], Never>
        let nearbyStores: AnyPublisher<[StoreSearchListItem], Never>
        let recentStores: AnyPublisher<[RecentStoreItem], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let viewStateSubject = CurrentValueSubject<StoreSearchViewState, Never>(.initial(viewType.emptyStateMessage))
        let searchResultsSubject = CurrentValueSubject<[StoreSearchListItem], Never>([])
        let nearbyStoresSubject = CurrentValueSubject<[StoreSearchListItem], Never>([])
        let recentStoresSubject = CurrentValueSubject<[RecentStoreItem], Never>([])
        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let initialQuery = self.initialSearchQuery {
                    self.handleSearch(
                        searchText: initialQuery,
                        viewStateSubject: viewStateSubject,
                        searchResultsSubject: searchResultsSubject,
                        nearbyStoresSubject: nearbyStoresSubject,
                        recentStoresSubject: recentStoresSubject
                    )
                } else {
                    self.initialFetch(
                        viewStateSubject: viewStateSubject,
                        nearbyStoresSubject: nearbyStoresSubject,
                        recentStoresSubject: recentStoresSubject
                    )
                }
            }
            .store(in: &cancellables)

        input.searchButtonTapped
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.handleSearch(
                    searchText: searchText,
                    viewStateSubject: viewStateSubject,
                    searchResultsSubject: searchResultsSubject,
                    nearbyStoresSubject: nearbyStoresSubject,
                    recentStoresSubject: recentStoresSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            viewState: viewStateSubject.eraseToAnyPublisher(),
            searchResults: searchResultsSubject.eraseToAnyPublisher(),
            nearbyStores: nearbyStoresSubject.eraseToAnyPublisher(),
            recentStores: recentStoresSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func initialFetch(
        viewStateSubject: CurrentValueSubject<StoreSearchViewState, Never>,
        nearbyStoresSubject: CurrentValueSubject<[StoreSearchListItem], Never>,
        recentStoresSubject: CurrentValueSubject<[RecentStoreItem], Never>
    ) {
        switch viewType {
        case .home:
            fetchNearbyStores(
                viewStateSubject: viewStateSubject,
                nearbyStoresSubject: nearbyStoresSubject
            )

        case .community:
            fetchRecentStores(
                viewStateSubject: viewStateSubject,
                recentStoresSubject: recentStoresSubject
            )
        }
    }

    private func fetchRecentStores(
        viewStateSubject: CurrentValueSubject<StoreSearchViewState, Never>,
        recentStoresSubject: CurrentValueSubject<[RecentStoreItem], Never>
    ) {
        orderRepository.getOrderList(status: nil)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    if case .failure = completion {
                        viewStateSubject.send(.initial(self.viewType.emptyStateMessage))
                    }
                },
                receiveValue: { [weak self] orderList in
                    guard let self = self else { return }

                    let groupedByStore = Dictionary(grouping: orderList, by: { $0.store.id })

                    let recentStoreItems = groupedByStore.compactMap { _, orders -> RecentStoreItem? in
                        guard let mostRecent = orders
                            .sorted(by: { ($0.paidAt ?? Date.distantPast) > ($1.paidAt ?? Date.distantPast) })
                            .first else {
                            return nil
                        }
                        return RecentStoreItem(store: mostRecent.store, paidAt: mostRecent.paidAt)
                    }
                    .sorted(by: { ($0.paidAt ?? Date.distantPast) > ($1.paidAt ?? Date.distantPast) })

                    if recentStoreItems.isEmpty {
                        viewStateSubject.send(.initial(self.viewType.emptyStateMessage))
                    } else {
                        recentStoresSubject.send(recentStoreItems)
                        viewStateSubject.send(.recentStores(recentStoreItems))
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func handleSearch(
        searchText: String,
        viewStateSubject: CurrentValueSubject<StoreSearchViewState, Never>,
        searchResultsSubject: CurrentValueSubject<[StoreSearchListItem], Never>,
        nearbyStoresSubject: CurrentValueSubject<[StoreSearchListItem], Never>,
        recentStoresSubject: CurrentValueSubject<[RecentStoreItem], Never>
    ) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            initialFetch(
                viewStateSubject: viewStateSubject,
                nearbyStoresSubject: nearbyStoresSubject,
                recentStoresSubject: recentStoresSubject
            )
            return
        }

        viewStateSubject.send(.searching)
        isLoadingSubject.send(true)

        storeRepository.searchStores(name: trimmedText)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] stores in
                    guard let self = self else { return }
                    let items = self.makeSearchItems(from: stores)
                    searchResultsSubject.send(items)
                    if items.isEmpty {
                        viewStateSubject.send(.empty("'\(trimmedText)'에 대한 검색 결과가 없습니다."))
                    } else {
                        viewStateSubject.send(.results(items))
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func fetchNearbyStores(
        viewStateSubject: CurrentValueSubject<StoreSearchViewState, Never>,
        nearbyStoresSubject: CurrentValueSubject<[StoreSearchListItem], Never>
    ) {
        guard let locationManager, let routeManager else {
            viewStateSubject.send(.empty("주변 매장을 불러올 수 없습니다."))
            return
        }

        isLoadingSubject.send(true)
        locationManager.checkPermissionAndStartUpdating()

        locationManager.locationSubject
            .compactMap { $0 }
            .prefix(1)
            .sink { [weak self] location in
                guard let self = self else { return }

                self.storeRepository.fetchNearbyStores(
                    category: nil,
                    longitude: location.coordinate.longitude,
                    latitude: location.coordinate.latitude,
                    maxDistance: 2000,
                    next: nil,
                    limit: nil,
                    orderBy: "distance"
                )
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoadingSubject.send(false)
                        if case .failure(let error) = completion {
                            self?.errorSubject.send(error.errorDescription)
                            viewStateSubject.send(.empty("주변 매장을 불러올 수 없습니다."))
                        }
                    },
                    receiveValue: { [weak self] result in
                        guard let self else { return }
                        let items = result.stores.map { store in
                            let distanceText = self.makeDistanceText(
                                location: location,
                                store: store,
                                routeManager: routeManager
                            )
                            return StoreSearchListItem(store: store, distanceText: distanceText)
                        }
                        nearbyStoresSubject.send(items)
                        if items.isEmpty {
                            viewStateSubject.send(.empty("주변 매장이 없습니다."))
                        } else {
                            viewStateSubject.send(.nearbyStores(items))
                        }
                    }
                )
                .store(in: &self.cancellables)
            }
            .store(in: &cancellables)
    }

    private func makeSearchItems(from stores: [StoreEntity]) -> [StoreSearchListItem] {
        guard let location = locationManager?.locationSubject.value,
              let routeManager else {
            return stores.map { StoreSearchListItem(store: $0, distanceText: nil) }
        }

        let items: [StoreSearchListItem] = stores.compactMap { store in
            let distanceKm = routeManager.calculateDistance(
                from: location.coordinate,
                to: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
            )
            let distanceMeters = distanceKm * 1000.0
            guard distanceMeters <= 2000 else { return nil }
            let distanceText = formatDistanceText(distanceMeters)
            return StoreSearchListItem(store: store, distanceText: distanceText)
        }

        return items
    }

    private func makeDistanceText(location: CLLocation, store: StoreEntity, routeManager: RouteManaging) -> String {
        let distanceKm = routeManager.calculateDistance(
            from: location.coordinate,
            to: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
        )
        let distanceMeters = distanceKm * 1000.0
        return formatDistanceText(distanceMeters)
    }

    private func formatDistanceText(_ distanceMeters: Double) -> String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m"
        }
        return String(format: "%.1fkm", distanceMeters / 1000.0)
    }
}
