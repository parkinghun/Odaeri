//
//  ShopDetailViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import Foundation
import Combine

final class ShopDetailViewModel: BaseViewModel, ViewModelType {
    private let storeRepository: StoreRepository
    private let storeId: String
    private let errorSubject = PassthroughSubject<String, Never>()

    init(
        storeId: String,
        storeRepository: StoreRepository = StoreRepositoryImpl()
    ) {
        self.storeId = storeId
        self.storeRepository = storeRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let storeLikeToggled: AnyPublisher<Bool, Never>
    }

    struct Output {
        let storeDetail: AnyPublisher<StoreEntity, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let storeDetailSubject = PassthroughSubject<StoreEntity, Never>()

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

        return Output(
            storeDetail: storeDetailSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
}
