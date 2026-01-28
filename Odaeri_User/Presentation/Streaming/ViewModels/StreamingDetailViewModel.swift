//
//  StreamingDetailViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import Foundation
import Combine
import AVFoundation

final class StreamingDetailViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        let seekToProgress: AnyPublisher<Float, Never>
        let settingsTapped: AnyPublisher<Void, Never>
        let currentTime: AnyPublisher<CMTime, Never>
        let duration: AnyPublisher<CMTime, Never>
        let isPlaying: AnyPublisher<Bool, Never>
        let externalSubtitles: AnyPublisher<[SubtitleItem]?, Never>
        let currentSubtitleIndex: AnyPublisher<Int?, Never>
        let manualScrollDetected: AnyPublisher<Void, Never>
        let returnToCurrentTapped: AnyPublisher<Void, Never>
        let subtitleCellTapped: AnyPublisher<Int, Never>
        let likeButtonTapped: AnyPublisher<Void, Never>
        let shareButtonTapped: AnyPublisher<Void, Never>
        let saveButtonTapped: AnyPublisher<Void, Never>
        let scriptButtonTapped: AnyPublisher<Void, Never>
        let availableSubtitles: AnyPublisher<[SubtitleTrack], Never>
    }

    struct Output {
        let streamURL: AnyPublisher<URL?, Never>
        let qualities: AnyPublisher<[VideoStreamQualityEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let currentTimeText: AnyPublisher<String, Never>
        let durationText: AnyPublisher<String, Never>
        let progress: AnyPublisher<Float, Never>
        let isPlayingState: AnyPublisher<Bool, Never>
        let showSpeedSettings: AnyPublisher<[Float], Never>
        let title: AnyPublisher<String, Never>
        let description: AnyPublisher<String, Never>
        let subtitles: AnyPublisher<[SubtitleItem], Never>
        let indexPathsToReload: AnyPublisher<[IndexPath], Never>
        let scrollToIndex: AnyPublisher<Int, Never>
        let showReturnButton: AnyPublisher<Bool, Never>
        let streamEntity: AnyPublisher<VideoStreamEntity, Never>
        let likeCount: AnyPublisher<Int, Never>
        let isLiked: AnyPublisher<Bool, Never>
        let isSaved: AnyPublisher<Bool, Never>
        let showScriptMenu: AnyPublisher<[SubtitleTrack], Never>
        let createdAt: AnyPublisher<String, Never>
        let showShareSheet: AnyPublisher<Void, Never>
    }

    var onPlayPauseTriggered: (() -> Void)?
    var onSeekRequested: ((CMTime) -> Void)?

    private let video: VideoEntity
    private let getStreamURLUseCase: GetVideoStreamURLUseCase
    private let toggleVideoLikeUseCase: ToggleVideoLikeUseCase
    private let toggleSaveVideoUseCase: ToggleSaveVideoUseCase
    private let checkVideoSavedUseCase: CheckVideoSavedUseCase

    private let streamURLSubject = PassthroughSubject<URL?, Never>()
    private let qualitiesSubject = PassthroughSubject<[VideoStreamQualityEntity], Never>()
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let currentTimeTextSubject = PassthroughSubject<String, Never>()
    private let durationTextSubject = PassthroughSubject<String, Never>()
    private let progressSubject = PassthroughSubject<Float, Never>()
    private let showSpeedSettingsSubject = PassthroughSubject<[Float], Never>()
    private let titleSubject = CurrentValueSubject<String, Never>("")
    private let descriptionSubject = CurrentValueSubject<String, Never>("")

    private let subtitlesSubject = CurrentValueSubject<[SubtitleItem], Never>([])
    private let indexPathsToReloadSubject = PassthroughSubject<[IndexPath], Never>()
    private let scrollToIndexSubject = PassthroughSubject<Int, Never>()
    private let showReturnButtonSubject = CurrentValueSubject<Bool, Never>(false)
    private let streamEntitySubject = PassthroughSubject<VideoStreamEntity, Never>()

    private let likeCountSubject = CurrentValueSubject<Int, Never>(0)
    private let isLikedSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSavedSubject = CurrentValueSubject<Bool, Never>(false)
    private let showScriptMenuSubject = PassthroughSubject<[SubtitleTrack], Never>()
    private let createdAtSubject = CurrentValueSubject<String, Never>("")
    private let showShareSheetSubject = PassthroughSubject<Void, Never>()

    private let saveToggleSubject = PassthroughSubject<Bool, Never>()

    private var availableSubtitleTracks: [SubtitleTrack] = []

    private var storedDuration: CMTime = .zero
    private var currentSubtitleIndex: Int?
    private var isManualScrolling = false
    private var isPlaying = false

    init(
        video: VideoEntity,
        getStreamURLUseCase: GetVideoStreamURLUseCase,
        toggleVideoLikeUseCase: ToggleVideoLikeUseCase,
        toggleSaveVideoUseCase: ToggleSaveVideoUseCase,
        checkVideoSavedUseCase: CheckVideoSavedUseCase
    ) {
        self.video = video
        self.getStreamURLUseCase = getStreamURLUseCase
        self.toggleVideoLikeUseCase = toggleVideoLikeUseCase
        self.toggleSaveVideoUseCase = toggleSaveVideoUseCase
        self.checkVideoSavedUseCase = checkVideoSavedUseCase
        super.init()

        titleSubject.send(video.title)
        descriptionSubject.send(video.description)
        likeCountSubject.send(video.likeCount)
        isLikedSubject.send(video.isLiked)

        if let createdAt = video.createdAt {
            createdAtSubject.send(createdAt.toRelativeTime)
        }

        checkInitialSaveState()
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.loadStreamURL()
            }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] in
                print("[StreamingDetailViewModel] playPauseTapped received")
                self?.onPlayPauseTriggered?()
            }
            .store(in: &cancellables)

        input.seekToProgress
            .sink { [weak self] progress in
                self?.handleSeek(progress: progress)
            }
            .store(in: &cancellables)

        input.settingsTapped
            .sink { [weak self] in
                self?.showSpeedSettings()
            }
            .store(in: &cancellables)

        input.currentTime
            .sink { [weak self] time in
                self?.handleCurrentTimeUpdate(time)
            }
            .store(in: &cancellables)

        input.duration
            .sink { [weak self] duration in
                self?.handleDurationUpdate(duration)
            }
            .store(in: &cancellables)

        input.isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)

        input.externalSubtitles
            .compactMap { $0 }
            .sink { [weak self] subtitles in
                self?.subtitlesSubject.send(subtitles)
            }
            .store(in: &cancellables)

        input.currentSubtitleIndex
            .sink { [weak self] index in
                self?.handleCurrentSubtitleIndexUpdate(index)
            }
            .store(in: &cancellables)

        input.manualScrollDetected
            .sink { [weak self] in
                self?.isManualScrolling = true
                self?.showReturnButtonSubject.send(true)
            }
            .store(in: &cancellables)

        input.returnToCurrentTapped
            .sink { [weak self] in
                guard let self = self else { return }
                self.isManualScrolling = false
                self.showReturnButtonSubject.send(false)

                if let currentIndex = self.currentSubtitleIndex {
                    self.scrollToIndexSubject.send(currentIndex)
                }
            }
            .store(in: &cancellables)

        input.subtitleCellTapped
            .sink { [weak self] index in
                guard let self = self else { return }
                let subtitles = self.subtitlesSubject.value
                guard index < subtitles.count else { return }

                let previousIndex = self.currentSubtitleIndex
                let subtitle = subtitles[index]
                let targetTime = CMTime(seconds: subtitle.startTime, preferredTimescale: 600)

                self.isManualScrolling = false
                self.showReturnButtonSubject.send(false)

                var indexPathsToReload: [IndexPath] = []
                if let prev = previousIndex, prev < subtitles.count, prev != index {
                    indexPathsToReload.append(IndexPath(row: prev, section: 0))
                }
                indexPathsToReload.append(IndexPath(row: index, section: 0))

                self.currentSubtitleIndex = index
                self.indexPathsToReloadSubject.send(indexPathsToReload)
                self.scrollToIndexSubject.send(index)

                self.onSeekRequested?(targetTime)
            }
            .store(in: &cancellables)

        input.likeButtonTapped
            .sink { [weak self] _ in
                guard let self = self else { return }
                let previousState = self.isLikedSubject.value
                let previousCount = self.likeCountSubject.value
                let newState = !previousState
                let newCount = previousCount + (newState ? 1 : -1)

                self.isLikedSubject.send(newState)
                self.likeCountSubject.send(newCount)

                self.handleLikeToggle(targetState: newState, previousState: previousState, previousCount: previousCount)
                print("좋아요 탭")
            }
            .store(in: &cancellables)

        input.shareButtonTapped
            .sink { [weak self] _ in
                self?.showShareSheetSubject.send(())
            }
            .store(in: &cancellables)

        input.saveButtonTapped
            .sink { [weak self] _ in
                guard let self = self else { return }
                let newState = !self.isSavedSubject.value
                self.isSavedSubject.send(newState)
                self.saveToggleSubject.send(newState)
            }
            .store(in: &cancellables)

        saveToggleSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] isSaved in
                self?.handleSaveToggle(isSaved: isSaved)
            }
            .store(in: &cancellables)

        input.scriptButtonTapped
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.showScriptMenuSubject.send(self.availableSubtitleTracks)
            }
            .store(in: &cancellables)

        input.availableSubtitles
            .sink { [weak self] tracks in
                self?.availableSubtitleTracks = tracks
            }
            .store(in: &cancellables)

        return Output(
            streamURL: streamURLSubject.eraseToAnyPublisher(),
            qualities: qualitiesSubject.eraseToAnyPublisher(),
            isLoading: loadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            currentTimeText: currentTimeTextSubject.eraseToAnyPublisher(),
            durationText: durationTextSubject.eraseToAnyPublisher(),
            progress: progressSubject.eraseToAnyPublisher(),
            isPlayingState: input.isPlaying,
            showSpeedSettings: showSpeedSettingsSubject.eraseToAnyPublisher(),
            title: titleSubject.eraseToAnyPublisher(),
            description: descriptionSubject.eraseToAnyPublisher(),
            subtitles: subtitlesSubject.eraseToAnyPublisher(),
            indexPathsToReload: indexPathsToReloadSubject.eraseToAnyPublisher(),
            scrollToIndex: scrollToIndexSubject.eraseToAnyPublisher(),
            showReturnButton: showReturnButtonSubject.eraseToAnyPublisher(),
            streamEntity: streamEntitySubject.eraseToAnyPublisher(),
            likeCount: likeCountSubject.eraseToAnyPublisher(),
            isLiked: isLikedSubject.eraseToAnyPublisher(),
            isSaved: isSavedSubject.eraseToAnyPublisher(),
            showScriptMenu: showScriptMenuSubject.eraseToAnyPublisher(),
            createdAt: createdAtSubject.eraseToAnyPublisher(),
            showShareSheet: showShareSheetSubject.eraseToAnyPublisher()
        )
    }

    private func loadStreamURL() {
        guard !loadingSubject.value else { return }

        loadingSubject.send(true)

        getStreamURLUseCase.execute(videoId: video.videoId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingSubject.send(false)

                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] streamEntity in
                    if let url = URL(string: streamEntity.streamUrl) {
                        self?.streamURLSubject.send(url)
                    } else {
                        self?.errorSubject.send("유효하지 않은 스트리밍 URL입니다")
                    }

                    self?.qualitiesSubject.send(streamEntity.qualities)
                    self?.streamEntitySubject.send(streamEntity)
                }
            )
            .store(in: &cancellables)
    }

    private func handleCurrentTimeUpdate(_ time: CMTime) {
        let seconds = time.seconds
        guard seconds.isFinite else { return }

        currentTimeTextSubject.send(formatTime(seconds))

        if storedDuration.seconds > 0 {
            let progress = Float(seconds / storedDuration.seconds)
            progressSubject.send(progress)
        }
    }

    private func handleDurationUpdate(_ duration: CMTime) {
        storedDuration = duration
        let seconds = duration.seconds
        guard seconds.isFinite, seconds > 0 else { return }

        durationTextSubject.send(formatTime(seconds))
    }

    private func handleSeek(progress: Float) {
        guard storedDuration.seconds > 0 else { return }
        let targetSeconds = Double(progress) * storedDuration.seconds
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        onSeekRequested?(targetTime)
    }

    private func showSpeedSettings() {
        let speeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        showSpeedSettingsSubject.send(speeds)
    }

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func handleCurrentSubtitleIndexUpdate(_ index: Int?) {
        let previousIndex = currentSubtitleIndex

        guard previousIndex != index else { return }

        currentSubtitleIndex = index

        guard !isManualScrolling && isPlaying else { return }

        var indexPathsToReload: [IndexPath] = []

        if let prev = previousIndex, prev < subtitlesSubject.value.count {
            indexPathsToReload.append(IndexPath(row: prev, section: 0))
        }

        if let currentIndex = index, currentIndex < subtitlesSubject.value.count {
            indexPathsToReload.append(IndexPath(row: currentIndex, section: 0))
            scrollToIndexSubject.send(currentIndex)
        }

        if !indexPathsToReload.isEmpty {
            indexPathsToReloadSubject.send(indexPathsToReload)
        }
    }

    private func handleLikeToggle(targetState: Bool, previousState: Bool, previousCount: Int) {
        toggleVideoLikeUseCase.execute(videoId: video.videoId, status: targetState)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[StreamingDetailViewModel] Like toggle failed: \(error.localizedDescription)")
                        self?.isLikedSubject.send(previousState)
                        self?.likeCountSubject.send(previousCount)
                        self?.errorSubject.send("좋아요 처리에 실패했습니다")
                    }
                },
                receiveValue: { _ in
                    print("[StreamingDetailViewModel] Like toggle succeeded")
                }
            )
            .store(in: &cancellables)
    }

    private func checkInitialSaveState() {
        checkVideoSavedUseCase.execute(videoId: video.videoId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSaved in
                self?.isSavedSubject.send(isSaved)
            }
            .store(in: &cancellables)
    }

    private func handleSaveToggle(isSaved: Bool) {
        let previousState = isSavedSubject.value

        toggleSaveVideoUseCase.execute(videoId: video.videoId, isSaved: isSaved)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                if !success {
                    print("[StreamingDetailViewModel] Save toggle failed")
                    self?.isSavedSubject.send(previousState)
                    self?.errorSubject.send("저장 처리에 실패했습니다")
                } else {
                    print("[StreamingDetailViewModel] Save toggle succeeded: \(isSaved)")
                }
            }
            .store(in: &cancellables)
    }
}
