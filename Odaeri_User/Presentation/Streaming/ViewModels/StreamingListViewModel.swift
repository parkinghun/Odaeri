//
//  StreamingListViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import Foundation
import Combine

final class StreamingListViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: StreamingCoordinator?

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refreshTriggered: AnyPublisher<Void, Never>
        let loadMore: AnyPublisher<Void, Never>
        let itemSelected: AnyPublisher<String, Never>
    }

    struct Output {
        let videoEntities: AnyPublisher<[VideoEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    private let getVideoListUseCase: GetVideoListUseCase

    private let videoEntitiesSubject = CurrentValueSubject<[VideoEntity], Never>([])
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    private var nextCursor: String?
    private var isLoadingMore = false

    init(getVideoListUseCase: GetVideoListUseCase) {
        self.getVideoListUseCase = getVideoListUseCase
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.loadVideos(isRefresh: false)
            }
            .store(in: &cancellables)

        input.refreshTriggered
            .sink { [weak self] _ in
                self?.loadVideos(isRefresh: true)
            }
            .store(in: &cancellables)

        input.loadMore
            .sink { [weak self] _ in
                self?.loadMoreVideos()
            }
            .store(in: &cancellables)

        input.itemSelected
            .sink { [weak self] videoId in
                guard let self = self else { return }
                if let video = self.videoEntitiesSubject.value.first(where: { $0.videoId == videoId }) {
                    self.coordinator?.showVideoDetail(video: video)
                }
            }
            .store(in: &cancellables)

        return Output(
            videoEntities: videoEntitiesSubject.eraseToAnyPublisher(),
            isLoading: loadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func loadVideos(isRefresh: Bool) {
        guard !loadingSubject.value else { return }

        if isRefresh {
            nextCursor = nil
        }

        loadingSubject.send(true)

        getVideoListUseCase.execute(next: isRefresh ? nil : nextCursor, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingSubject.send(false)

                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] result in
                    if isRefresh {
                        self?.videoEntitiesSubject.send(result.videos)
                    } else {
                        let current = self?.videoEntitiesSubject.value ?? []
                        self?.videoEntitiesSubject.send(current + result.videos)
                    }

                    self?.nextCursor = result.nextCursor
                }
            )
            .store(in: &cancellables)
    }

    private func loadMoreVideos() {
        guard !isLoadingMore,
              let next = nextCursor,
              !loadingSubject.value else { return }

        isLoadingMore = true

        getVideoListUseCase.execute(next: next, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMore = false

                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] result in
                    let current = self?.videoEntitiesSubject.value ?? []
                    self?.videoEntitiesSubject.send(current + result.videos)

                    self?.nextCursor = result.nextCursor
                }
            )
            .store(in: &cancellables)
    }
}
