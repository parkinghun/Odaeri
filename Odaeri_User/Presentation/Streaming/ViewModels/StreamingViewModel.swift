//
//  StreamingViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import Foundation
import Combine
import AVFoundation

final class StreamingViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: StreamingCoordinator?

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let didChangeIndex: AnyPublisher<Int, Never>
        let didEnterBackground: AnyPublisher<Void, Never>
        let didBecomeActive: AnyPublisher<Void, Never>
        let qualitySelected: AnyPublisher<QualitySelection, Never>
        let likeToggled: AnyPublisher<LikeToggleEvent, Never>
        let scrollVelocity: AnyPublisher<ScrollVelocityEvent, Never>
    }

    struct Output {
        let videos: AnyPublisher<[StreamingVideoDisplay], Never>
        let currentIndex: AnyPublisher<Int, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let likeUpdated: AnyPublisher<StreamingVideoDisplay, Never>
    }

    struct QualitySelection: Hashable {
        let videoId: String
        let qualityURL: String
    }

    struct LikeToggleEvent: Hashable {
        let videoId: String
        let newState: Bool
    }

    struct ScrollVelocityEvent: Hashable {
        let velocity: CGFloat
        let index: Int
    }

    struct TokenExpirationEvent {
        let videoId: String
        let lastTime: CMTime
        let index: Int
    }

    enum PlaybackQuality {
        case low
        case medium
        case high

        static func from(velocity: CGFloat) -> PlaybackQuality {
            let absVelocity = abs(velocity)
            if absVelocity > 1500 {
                return .low
            } else if absVelocity > 500 {
                return .medium
            } else {
                return .high
            }
        }
    }

    private enum Constant {
        static let prepareAhead = 1
        static let prefetchAhead = 2
    }

    private let videoRepository: VideoRepository
    private let playerPool: PlayerPoolManager
    private let videosSubject = CurrentValueSubject<[StreamingVideoDisplay], Never>([])
    private let currentIndexSubject = CurrentValueSubject<Int, Never>(0)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let likeUpdatedSubject = PassthroughSubject<StreamingVideoDisplay, Never>()

    private var videos: [VideoEntity] = []
    private var streams: [String: VideoStreamEntity] = [:]
    private var inFlightStreams = Set<String>()
    private var currentQuality: PlaybackQuality = .high
    private var pendingLikeRequests: [String: Bool] = [:]

    init(
        videoRepository: VideoRepository = VideoRepositoryImpl(),
        playerPool: PlayerPoolManager = PlayerPoolManager()
    ) {
        self.videoRepository = videoRepository
        self.playerPool = playerPool
        super.init()
        setupTokenExpirationHandler()
    }

    private func setupTokenExpirationHandler() {
        playerPool.onTokenExpiration = { [weak self] videoId, lastTime, index in
            guard let self = self else { return }
            print("[StreamingViewModel] 토큰 만료 이벤트 수신: \(videoId)")

            self.streams.removeValue(forKey: videoId)

            self.videoRepository.getVideoStreamingURL(videoId: videoId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("[StreamingViewModel] 토큰 재발급 실패: \(error.errorDescription)")
                        }
                    },
                    receiveValue: { [weak self] stream in
                        guard let self = self else { return }
                        print("[StreamingViewModel] 토큰 재발급 성공, 재생 재개 시도")
                        self.streams[videoId] = stream
                        StreamURLCache.shared.set(stream, for: videoId)
                        self.playerPool.resumeFromTokenExpiration(
                            videoId: videoId,
                            stream: stream,
                            seekTo: lastTime,
                            index: index
                        )
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchVideos()
            }
            .store(in: &cancellables)

        input.didChangeIndex
            .sink { [weak self] index in
                self?.currentIndexSubject.send(index)
                self?.prepareForIndex(index)
            }
            .store(in: &cancellables)

        input.didEnterBackground
            .sink { [weak self] _ in
                self?.playerPool.pauseAll()
            }
            .store(in: &cancellables)

        input.didBecomeActive
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.playerPool.resume(index: self.currentIndexSubject.value)
            }
            .store(in: &cancellables)

        input.qualitySelected
            .sink { [weak self] selection in
                self?.switchQuality(selection)
            }
            .store(in: &cancellables)

        input.likeToggled
            .sink { [weak self] event in
                self?.toggleLikeOptimistic(event: event)
            }
            .store(in: &cancellables)

        input.likeToggled
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] event in
                self?.sendLikeRequest(event: event)
            }
            .store(in: &cancellables)

        input.scrollVelocity
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleScrollVelocity(event)
            }
            .store(in: &cancellables)

        return Output(
            videos: videosSubject.eraseToAnyPublisher(),
            currentIndex: currentIndexSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            likeUpdated: likeUpdatedSubject.eraseToAnyPublisher()
        )
    }

    func player(for index: Int) -> AVPlayer {
        return playerPool.player(for: index)
    }

    func video(at index: Int) -> VideoEntity? {
        guard videos.indices.contains(index) else { return nil }
        return videos[index]
    }

    func stream(for videoId: String) -> VideoStreamEntity? {
        return streams[videoId]
    }

    private func fetchVideos() {
        isLoadingSubject.send(true)
        videoRepository.fetchVideoList(next: nil, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] videos in
                    guard let self = self else { return }
                    self.videos = videos
                    let displays = videos.map(self.makeDisplay)
                    self.videosSubject.send(displays)
                    self.prepareForIndex(0)
                }
            )
            .store(in: &cancellables)
    }

    private func prepareForIndex(_ index: Int) {
        guard let currentVideo = video(at: index) else { return }
        requestStreamIfNeeded(for: currentVideo, index: index, purpose: .prepareItem)

        let prepareIndex = index + Constant.prepareAhead
        if let nextVideo = video(at: prepareIndex) {
            requestStreamIfNeeded(for: nextVideo, index: prepareIndex, purpose: .prepareItem)
        }

        let prefetchIndex = index + Constant.prefetchAhead
        if let prefetchVideo = video(at: prefetchIndex) {
            requestStreamIfNeeded(for: prefetchVideo, index: prefetchIndex, purpose: .prefetchPlaylist)
        }

        let keepIds = Set([index - 2, index - 1, index, index + 1, index + 2]
            .compactMap { video(at: $0)?.videoId })
        playerPool.cleanup(keepingVideoIds: keepIds)
    }

    private func requestStreamIfNeeded(for video: VideoEntity, index: Int, purpose: StreamPurpose) {
        if video.videoType == .file {
            if case .prepareItem = purpose {
                playerPool.preparePlayer(for: index, video: video, stream: nil)
            }
            return
        }

        if let stream = streams[video.videoId] {
            handleStream(stream, for: video, index: index, purpose: purpose)
            return
        }

        if let cachedStream = StreamURLCache.shared.get(for: video.videoId) {
            print("[StreamingViewModel] NSCache에서 stream URL 복원: \(video.videoId)")
            streams[video.videoId] = cachedStream
            handleStream(cachedStream, for: video, index: index, purpose: purpose)
            return
        }

        guard !inFlightStreams.contains(video.videoId) else { return }
        inFlightStreams.insert(video.videoId)

        print("[StreamingViewModel] API 호출 (조회수 +1): \(video.videoId)")
        videoRepository.getVideoStreamingURL(videoId: video.videoId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.inFlightStreams.remove(video.videoId)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] stream in
                    guard let self = self else { return }
                    self.streams[video.videoId] = stream
                    StreamURLCache.shared.set(stream, for: video.videoId)
                    self.handleStream(stream, for: video, index: index, purpose: purpose)
                }
            )
            .store(in: &cancellables)
    }

    private func handleStream(
        _ stream: VideoStreamEntity,
        for video: VideoEntity,
        index: Int,
        purpose: StreamPurpose
    ) {
        switch purpose {
        case .prepareItem:
            if index == currentIndexSubject.value {
                print("[Streaming] stream url: \(stream.streamUrl)")
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.playerPool.preparePlayer(for: index, video: video, stream: stream)
                if index == self.currentIndexSubject.value {
                    self.playerPool.resume(index: index)
                }
            }
        case .prefetchPlaylist:
            playerPool.prefetchPlaylist(for: video, stream: stream)
        }
    }

    private func switchQuality(_ selection: QualitySelection) {
        guard let url = URL(string: selection.qualityURL) else { return }
        playerPool.switchQuality(videoId: selection.videoId, qualityURL: url, autoplay: true)
    }

    private func toggleLikeOptimistic(event: LikeToggleEvent) {
        guard let index = videos.firstIndex(where: { $0.videoId == event.videoId }) else { return }
        let current = videos[index]
        let updated = VideoEntity(
            videoId: current.videoId,
            fileName: current.fileName,
            title: current.title,
            description: current.description,
            duration: current.duration,
            thumbnailUrl: current.thumbnailUrl,
            availableQualities: current.availableQualities,
            viewCount: current.viewCount,
            likeCount: max(0, current.likeCount + (event.newState ? 1 : -1)),
            isLiked: event.newState,
            createdAt: current.createdAt
        )
        videos[index] = updated
        pendingLikeRequests[event.videoId] = event.newState

        let updatedDisplay = makeDisplay(updated)
        likeUpdatedSubject.send(updatedDisplay)
    }

    private func sendLikeRequest(event: LikeToggleEvent) {
        guard let finalState = pendingLikeRequests[event.videoId] else { return }
        pendingLikeRequests.removeValue(forKey: event.videoId)

        videoRepository.toggleVideoLike(videoId: event.videoId, status: finalState)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func makeDisplay(_ entity: VideoEntity) -> StreamingVideoDisplay {
        let createdAtText = entity.createdAt?.toRelativeTime ?? "방금 전"
        return StreamingVideoDisplay(
            videoId: entity.videoId,
            title: entity.title,
            description: entity.description,
            likeCountText: formatCount(entity.likeCount),
            viewCountText: formatCount(entity.viewCount),
            isLiked: entity.isLiked,
            createdAtText: createdAtText,
            thumbnailUrl: entity.thumbnailUrl
        )
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            let value = Double(count) / 10000.0
            let text = String(format: "%.1f", value)
            return "\(trimTrailingZero(text))만"
        }
        if count >= 1000 {
            let value = Double(count) / 1000.0
            let text = String(format: "%.1f", value)
            return "\(trimTrailingZero(text))천"
        }
        return "\(count)"
    }

    private func trimTrailingZero(_ text: String) -> String {
        if text.hasSuffix(".0") {
            return String(text.dropLast(2))
        }
        return text
    }

    private func handleScrollVelocity(_ event: ScrollVelocityEvent) {
        let newQuality = PlaybackQuality.from(velocity: event.velocity)

        guard newQuality != currentQuality else { return }

        currentQuality = newQuality

        switch newQuality {
        case .low:
            print("[StreamingViewModel] 고속 스크롤 감지: 저화질 모드")
            playerPool.setPreferredQuality(.low)
        case .medium:
            print("[StreamingViewModel] 중속 스크롤 감지: 중화질 모드")
            playerPool.setPreferredQuality(.medium)
        case .high:
            print("[StreamingViewModel] 저속/정지 감지: 고화질 모드")
            playerPool.setPreferredQuality(.high)

            if let video = video(at: event.index),
               let stream = streams[video.videoId],
               let highQualityURL = selectHighQualityURL(from: stream) {
                playerPool.switchQuality(videoId: video.videoId, qualityURL: highQualityURL, autoplay: false)
            }
        }
    }

    private func selectHighQualityURL(from stream: VideoStreamEntity) -> URL? {
        return URL(string: stream.streamUrl)
    }
}

private extension StreamingViewModel {
    enum StreamPurpose {
        case prepareItem
        case prefetchPlaylist
    }
}
