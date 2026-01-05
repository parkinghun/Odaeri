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
    private let storeRepository: StoreRepository
    private let locationManager: LocationManager
    private let storeId: String
    private let errorSubject = PassthroughSubject<String, Never>()

    init(
        storeId: String,
        storeRepository: StoreRepository = StoreRepositoryImpl(),
        locationManager: LocationManager = .shared
    ) {
        self.storeId = storeId
        self.storeRepository = storeRepository
        self.locationManager = locationManager
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let storeLikeToggled: AnyPublisher<Bool, Never>
    }

    struct Output {
        let storeDetail: AnyPublisher<StoreEntity, Never>
        let currentLocation: AnyPublisher<CLLocation?, Never>
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

        return Output(
            storeDetail: storeDetailSubject.eraseToAnyPublisher(),
            currentLocation: currentLocationSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
}
