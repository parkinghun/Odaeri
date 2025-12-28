//
//  HomeViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import Foundation
import Combine

final class HomeViewModel: BaseViewModel, ViewModelType {
    private let storeRepository: StoreRepository
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    init(storeRepository: StoreRepository = StoreRepositoryImpl()) {
        self.storeRepository = storeRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let categorySelected: AnyPublisher<Category?, Never>
        let refreshTriggered: AnyPublisher<Void, Never>
    }

    struct Output {
        let popularStores: AnyPublisher<[StoreEntity], Never>
        let myPickupStores: AnyPublisher<[StoreEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let popularStoresSubject = PassthroughSubject<[StoreEntity], Never>()
        let myPickupStoresSubject = PassthroughSubject<[StoreEntity], Never>()

        // viewDidLoad 시 인기 맛집 불러오기
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchPopularStores(subject: popularStoresSubject)
                self?.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 카테고리 선택 시 필터링
        input.categorySelected
            .sink { [weak self] category in
                self?.fetchPopularStores(category: category?.title, subject: popularStoresSubject)
                self?.fetchMyPickupStores(category: category?.title, subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 새로고침
        input.refreshTriggered
            .sink { [weak self] _ in
                self?.fetchPopularStores(subject: popularStoresSubject)
                self?.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        return Output(
            popularStores: popularStoresSubject.eraseToAnyPublisher(),
            myPickupStores: myPickupStoresSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func fetchPopularStores(
        category: String? = nil,
        subject: PassthroughSubject<[StoreEntity], Never>
    ) {
        isLoadingSubject.send(true)

        storeRepository.fetchPopularStores(category: category)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { stores in
                    subject.send(stores)
                }
            )
            .store(in: &cancellables)
    }

    private func fetchMyPickupStores(
        category: String? = nil,
        subject: PassthroughSubject<[StoreEntity], Never>
    ) {
        // TODO: 실제 위치 정보 사용
        let defaultLongitude = 126.9780
        let defaultLatitude = 37.5665

        storeRepository.fetchNearbyStores(
            category: category,
            longitude: defaultLongitude,
            latitude: defaultLatitude,
            distance: 5000, // 5km
            next: nil,
            limit: 10
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            },
            receiveValue: { result in
                subject.send(result.stores)
            }
        )
        .store(in: &cancellables)
    }
}
