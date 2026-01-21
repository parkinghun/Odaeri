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
    }

    var onPlayPauseTriggered: (() -> Void)?
    var onSeekRequested: ((CMTime) -> Void)?

    private let video: VideoEntity
    private let getStreamURLUseCase: GetVideoStreamURLUseCase

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

    private var storedDuration: CMTime = .zero

    init(video: VideoEntity, getStreamURLUseCase: GetVideoStreamURLUseCase) {
        self.video = video
        self.getStreamURLUseCase = getStreamURLUseCase
        super.init()

        titleSubject.send(video.title)
        descriptionSubject.send(video.description)
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.loadStreamURL()
            }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] in
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
            description: descriptionSubject.eraseToAnyPublisher()
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
}
