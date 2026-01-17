//
//  StoreSearchViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation
import Combine

struct RecentStoreItem {
    let store: OrderStoreInfoEntity
    let paidAt: Date?
}

enum StoreSearchViewState {
    case initial(String)
    case searching
    case results([StoreEntity])
    case empty(String)
    case recentStores([RecentStoreItem])

    var shouldShowTableView: Bool {
        switch self {
        case .results, .recentStores:
            return true
        case .initial, .searching, .empty:
            return false
        }
    }

    var shouldShowEmptyLabel: Bool {
        switch self {
        case .initial, .empty:
            return true
        case .searching, .results, .recentStores:
            return false
        }
    }

    var emptyMessage: String? {
        switch self {
        case .initial(let message), .empty(let message):
            return message
        case .searching, .results, .recentStores:
            return nil
        }
    }

    var sectionTitle: String? {
        switch self {
        case .results:
            return "검색 결과"
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

    init(
        viewType: StoreSearchViewType,
        initialSearchQuery: String? = nil,
        storeRepository: StoreRepository = StoreRepositoryImpl(),
        orderRepository: OrderRepository = OrderRepositoryImpl()
    ) {
        self.viewType = viewType
        self.initialSearchQuery = initialSearchQuery
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let searchButtonTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let viewState: AnyPublisher<StoreSearchViewState, Never>
        let searchResults: AnyPublisher<[StoreEntity], Never>
        let recentStores: AnyPublisher<[RecentStoreItem], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let viewStateSubject = CurrentValueSubject<StoreSearchViewState, Never>(.initial(viewType.emptyStateMessage))
        let searchResultsSubject = CurrentValueSubject<[StoreEntity], Never>([])
        let recentStoresSubject = CurrentValueSubject<[RecentStoreItem], Never>([])
        let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
        let errorSubject = PassthroughSubject<String, Never>()

        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let initialQuery = self.initialSearchQuery {
                    self.handleSearch(
                        searchText: initialQuery,
                        viewStateSubject: viewStateSubject,
                        searchResultsSubject: searchResultsSubject,
                        recentStoresSubject: recentStoresSubject,
                        isLoadingSubject: isLoadingSubject,
                        errorSubject: errorSubject
                    )
                } else {
                    self.initialFetch(
                        viewStateSubject: viewStateSubject,
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
                    recentStoresSubject: recentStoresSubject,
                    isLoadingSubject: isLoadingSubject,
                    errorSubject: errorSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            viewState: viewStateSubject.eraseToAnyPublisher(),
            searchResults: searchResultsSubject.eraseToAnyPublisher(),
            recentStores: recentStoresSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func initialFetch(
        viewStateSubject: CurrentValueSubject<StoreSearchViewState, Never>,
        recentStoresSubject: CurrentValueSubject<[RecentStoreItem], Never>
    ) {
        switch viewType {
        case .home:
            viewStateSubject.send(.initial(viewType.emptyStateMessage))

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
        searchResultsSubject: CurrentValueSubject<[StoreEntity], Never>,
        recentStoresSubject: CurrentValueSubject<[RecentStoreItem], Never>,
        isLoadingSubject: CurrentValueSubject<Bool, Never>,
        errorSubject: PassthroughSubject<String, Never>
    ) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            initialFetch(
                viewStateSubject: viewStateSubject,
                recentStoresSubject: recentStoresSubject
            )
            return
        }

        viewStateSubject.send(.searching)
        isLoadingSubject.send(true)

        storeRepository.searchStores(name: trimmedText)
            .sink(
                receiveCompletion: { completion in
                    isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { stores in
                    searchResultsSubject.send(stores)
                    if stores.isEmpty {
                        viewStateSubject.send(.empty("'\(trimmedText)'에 대한 검색 결과가 없습니다."))
                    } else {
                        viewStateSubject.send(.results(stores))
                    }
                }
            )
            .store(in: &cancellables)
    }
}
