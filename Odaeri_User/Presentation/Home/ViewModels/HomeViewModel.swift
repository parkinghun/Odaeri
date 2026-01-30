//
//  HomeViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import Foundation
import Combine
import CoreLocation

final class HomeViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: HomeCoordinator?

    private let storeRepository: StoreRepository
    private let bannerRepository: BannerRepository
    private let locationManager: LocationManaging
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    private var banners: [BannerEntity] = []
    private var currentBannerIndex: Int = 0
    private var bannerTimer: Timer?
    private let currentBannerIndexSubject = PassthroughSubject<Int, Never>()

    private var likeSubjects: [String: PassthroughSubject<Bool, Never>] = [:]

    private var currentCategory: String?
    private var currentSortType: String = "distance"
    private var currentIsPicchelin: Bool?
    private var currentIsPick: Bool?

    init(
        storeRepository: StoreRepository,
        bannerRepository: BannerRepository,
        locationManager: LocationManaging
    ) {
        self.storeRepository = storeRepository
        self.bannerRepository = bannerRepository
        self.locationManager = locationManager
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let searchBarTapped: AnyPublisher<Void, Never>
        let keywordSearchTapped: AnyPublisher<String, Never>
        let categorySelected: AnyPublisher<Category?, Never>
        let refreshTriggered: AnyPublisher<Void, Never>
        let userScrolledBanner: AnyPublisher<Int, Never>
        let bannerSelected: AnyPublisher<BannerEntity, Never>
        let storeLikeToggled: AnyPublisher<LikeButton.TapEvent, Never>
        let storeSelected: AnyPublisher<String, Never>
        let sortTypeChanged: AnyPublisher<String, Never>
        let filterTypeChanged: AnyPublisher<(isPicchelin: Bool?, isPick: Bool?), Never>
    }

    struct Output {
        let popularKeywords: AnyPublisher<[String], Never>
        let banners: AnyPublisher<[BannerEntity], Never>
        let popularStores: AnyPublisher<[StoreEntity], Never>
        let myPickupStores: AnyPublisher<[StoreEntity], Never>
        let currentBannerIndex: AnyPublisher<Int, Never>
        let currentLocation: AnyPublisher<CLLocation?, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let likeToggleFailed: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let popularKeywordsSubject = PassthroughSubject<[String], Never>()
        let bannersSubject = PassthroughSubject<[BannerEntity], Never>()
        let popularStoresSubject = PassthroughSubject<[StoreEntity], Never>()
        let myPickupStoresSubject = PassthroughSubject<[StoreEntity], Never>()
        let likeToggleFailedSubject = PassthroughSubject<String, Never>()
        let currentLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)

        // 위치 업데이트 구독
        locationManager.locationSubject
            .sink { location in
                currentLocationSubject.send(location)
            }
            .store(in: &cancellables)

        // viewDidLoad 시 데이터 불러오기 및 위치 권한 요청
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.locationManager.checkPermissionAndStartUpdating()
                self?.fetchPopularKeywords(subject: popularKeywordsSubject)
                self?.fetchBanners(subject: bannersSubject)
                self?.fetchPopularStores(subject: popularStoresSubject)
                self?.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 카테고리 선택 시 필터링
        input.categorySelected
            .sink { [weak self] category in
                guard let self = self else { return }
                self.currentCategory = category?.title
                self.fetchPopularStores(category: category?.title, subject: popularStoresSubject)
                self.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 정렬 타입 변경
        input.sortTypeChanged
            .sink { [weak self] sortType in
                guard let self = self else { return }
                self.currentSortType = sortType
                self.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 필터 타입 변경
        input.filterTypeChanged
            .sink { [weak self] filter in
                guard let self = self else { return }
                self.currentIsPicchelin = filter.isPicchelin
                self.currentIsPick = filter.isPick
                self.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 새로고침
        input.refreshTriggered
            .sink { [weak self] _ in
                self?.fetchPopularKeywords(subject: popularKeywordsSubject)
                self?.fetchBanners(subject: bannersSubject)
                self?.fetchPopularStores(subject: popularStoresSubject)
                self?.fetchMyPickupStores(subject: myPickupStoresSubject)
            }
            .store(in: &cancellables)

        // 배너 데이터 수신 시 자동 슬라이드 시작
        bannersSubject
            .sink { [weak self] banners in
                self?.banners = banners
                self?.currentBannerIndex = 0
                self?.startBannerTimer()
            }
            .store(in: &cancellables)

        // 사용자가 배너를 수동으로 스크롤한 경우
        input.userScrolledBanner
            .sink { [weak self] index in
                self?.currentBannerIndex = index
                self?.startBannerTimer()
            }
            .store(in: &cancellables)

        input.searchBarTapped
            .sink { [weak self] _ in
                self?.coordinator?.showStoreSearch()
            }
            .store(in: &cancellables)

        input.keywordSearchTapped
            .sink { [weak self] keyword in
                self?.coordinator?.showStoreSearch(with: keyword)
            }
            .store(in: &cancellables)

        input.bannerSelected
            .compactMap { banner -> String? in
                guard banner.action.isWebView, let path = banner.action.webViewPath else { return nil }
                return path
            }
            .sink { [weak self] path in
                self?.coordinator?.showEventWeb(path: path)
            }
            .store(in: &cancellables)

        input.storeLikeToggled
            .sink { [weak self] event in
                guard let self = self else { return }

                // storeId별 독립적인 Subject 생성 (없으면 새로 생성)
                if self.likeSubjects[event.storeId] == nil {
                    let subject = PassthroughSubject<Bool, Never>()
                    self.likeSubjects[event.storeId] = subject

                    // 각 storeId별로 독립적인 debounce 적용
                    subject
                        .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
                        .sink { [weak self] newState in
                            self?.toggleStoreLike(
                                storeId: event.storeId,
                                newState: newState,
                                failedSubject: likeToggleFailedSubject
                            )
                        }
                        .store(in: &self.cancellables)
                }

                // 해당 storeId의 Subject로 이벤트 전송
                self.likeSubjects[event.storeId]?.send(event.newState)
            }
            .store(in: &cancellables)

        input.storeSelected
            .sink { [weak self] storeId in
                self?.coordinator?.showStoreDetail(storeId: storeId)
            }
            .store(in: &cancellables)

        return Output(
            popularKeywords: popularKeywordsSubject.eraseToAnyPublisher(),
            banners: bannersSubject.eraseToAnyPublisher(),
            popularStores: popularStoresSubject.eraseToAnyPublisher(),
            myPickupStores: myPickupStoresSubject.eraseToAnyPublisher(),
            currentBannerIndex: currentBannerIndexSubject.eraseToAnyPublisher(),
            currentLocation: currentLocationSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            likeToggleFailed: likeToggleFailedSubject.eraseToAnyPublisher()
        )
    }

    private func fetchPopularKeywords(subject: PassthroughSubject<[String], Never>) {
        storeRepository.fetchPopularKeywords()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { keywords in
                    subject.send(keywords)
                }
            )
            .store(in: &cancellables)
    }

    private func fetchBanners(subject: PassthroughSubject<[BannerEntity], Never>) {
        bannerRepository.fetchBanners()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { banners in
                    subject.send(banners)
                }
            )
            .store(in: &cancellables)
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
        subject: PassthroughSubject<[StoreEntity], Never>
    ) {
        storeRepository.fetchNearbyStores(
            category: currentCategory,
            longitude: nil,
            latitude: nil,
            maxDistance: nil,
            next: nil,
            limit: 10,
            orderBy: currentSortType
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            },
            receiveValue: { [weak self] result in
                guard let self = self else { return }
                var filteredStores = result.stores

                if let isPicchelin = self.currentIsPicchelin, isPicchelin {
                    filteredStores = filteredStores.filter { $0.isPicchelin }
                }

                if let isPick = self.currentIsPick, isPick {
                    filteredStores = filteredStores.filter { $0.isPick }
                }

                subject.send(filteredStores)
            }
        )
        .store(in: &cancellables)
    }

    private func startBannerTimer() {
        stopBannerTimer()

        guard !banners.isEmpty else { return }

        bannerTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.showNextBanner()
        }
    }

    private func stopBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = nil
    }

    private func showNextBanner() {
        guard !banners.isEmpty else { return }

        currentBannerIndex = (currentBannerIndex + 1) % banners.count
        currentBannerIndexSubject.send(currentBannerIndex)
    }

    private func toggleStoreLike(
        storeId: String,
        newState: Bool,
        failedSubject: PassthroughSubject<String, Never>
    ) {
        storeRepository.toggleLike(storeId: storeId, status: newState)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        failedSubject.send(storeId)
                        print(#function, error)
                    }
                },
                receiveValue: { _ in
                    // Success - optimistic UI already updated
                }
            )
            .store(in: &cancellables)
    }

    deinit {
        stopBannerTimer()
    }
}
