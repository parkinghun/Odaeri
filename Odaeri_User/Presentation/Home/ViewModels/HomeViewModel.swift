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
    private let bannerRepository: BannerRepository
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    private var banners: [BannerEntity] = []
    private var currentBannerIndex: Int = 0
    private var bannerTimer: Timer?
    private let currentBannerIndexSubject = PassthroughSubject<Int, Never>()

    private var likeSubjects: [String: PassthroughSubject<Bool, Never>] = [:]

    init(
        storeRepository: StoreRepository = StoreRepositoryImpl(),
        bannerRepository: BannerRepository = BannerRepositoryImpl()
    ) {
        self.storeRepository = storeRepository
        self.bannerRepository = bannerRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let categorySelected: AnyPublisher<Category?, Never>
        let refreshTriggered: AnyPublisher<Void, Never>
        let userScrolledBanner: AnyPublisher<Int, Never>
        let storeLikeToggled: AnyPublisher<LikeButton.TapEvent, Never>
    }

    struct Output {
        let popularKeywords: AnyPublisher<[String], Never>
        let banners: AnyPublisher<[BannerEntity], Never>
        let popularStores: AnyPublisher<[StoreEntity], Never>
        let myPickupStores: AnyPublisher<[StoreEntity], Never>
        let currentBannerIndex: AnyPublisher<Int, Never>
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

        // viewDidLoad 시 데이터 불러오기
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchPopularKeywords(subject: popularKeywordsSubject)
                self?.fetchBanners(subject: bannersSubject)
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

        return Output(
            popularKeywords: popularKeywordsSubject.eraseToAnyPublisher(),
            banners: bannersSubject.eraseToAnyPublisher(),
            popularStores: popularStoresSubject.eraseToAnyPublisher(),
            myPickupStores: myPickupStoresSubject.eraseToAnyPublisher(),
            currentBannerIndex: currentBannerIndexSubject.eraseToAnyPublisher(),
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
        category: String? = nil,
        subject: PassthroughSubject<[StoreEntity], Never>
    ) {
        // TODO: 실제 위치 정보 사용
        let defaultLongitude = 126.9780
        let defaultLatitude = 37.5665

        storeRepository.fetchNearbyStores(
            category: nil,
            longitude: nil,
            latitude: nil,
            distance: nil, // 5km
            next: nil,
            limit: 10,
            orderBy: "distance"
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
