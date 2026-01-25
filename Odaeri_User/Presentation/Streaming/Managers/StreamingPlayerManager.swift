//
//  StreamingPlayerManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import AVFoundation
import AVKit
import Combine

final class StreamingPlayerManager {
    private let player: AVPlayer = {
        let player = AVPlayer()
        player.appliesMediaSelectionCriteriaAutomatically = true
        return player
    }()
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private let videoRepository: VideoRepository
    private var pipController: AVPictureInPictureController?

    private let currentTimeSubject = PassthroughSubject<CMTime, Never>()
    private let durationSubject = PassthroughSubject<CMTime, Never>()
    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let currentRateSubject = CurrentValueSubject<Float, Never>(1.0)

    private var preferredRate: Float = 1.0
    private var isFastForwarding = false

    private(set) lazy var subtitleManager: SubtitleManager = {
        return SubtitleManager(player: player, videoRepository: videoRepository)
    }()

    var currentTimePublisher: AnyPublisher<CMTime, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<CMTime, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var currentRatePublisher: AnyPublisher<Float, Never> {
        currentRateSubject.eraseToAnyPublisher()
    }

    init(videoRepository: VideoRepository) {
        self.videoRepository = videoRepository
        setupAudioSession()
        setupTimeObserver()
        observePlayerStatus()
    }

    deinit {
        removeTimeObserver()
    }

    func loadVideo(url: URL) {
        removeTimeObserver()
        playerItem = AVPlayerItem(url: url)

        guard let playerItem = playerItem else { return }

        playerItem.audioTimePitchAlgorithm = .timeDomain

        if let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            playerItem.select(nil, in: legibleGroup)
        }

        player.replaceCurrentItem(with: playerItem)

        observePlayerItem(playerItem)
        setupTimeObserver()
    }

    func play() {
        print("[StreamingPlayerManager] play() called, preferredRate: \(preferredRate), isFastForwarding: \(isFastForwarding)")
        player.rate = isFastForwarding ? 2.0 : preferredRate
        print("[StreamingPlayerManager] after play(), rate: \(player.rate)")
    }

    func pause() {
        print("[StreamingPlayerManager] pause() called, current rate: \(player.rate)")
        player.pause()
        print("[StreamingPlayerManager] after pause(), rate: \(player.rate)")
    }

    func seek(to time: CMTime, completion: (() -> Void)? = nil) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            if finished {
                completion?()
            }
        }
    }

    func setPreferredRate(_ rate: Float) {
        preferredRate = rate
        currentRateSubject.send(rate)

        if isPlayingSubject.value && !isFastForwarding {
            player.rate = rate
        }
    }

    func startFastForward() {
        guard !isFastForwarding else { return }
        isFastForwarding = true

        if isPlayingSubject.value {
            player.rate = 2.0
        }
    }

    func stopFastForward() {
        guard isFastForwarding else { return }
        isFastForwarding = false

        if isPlayingSubject.value {
            player.rate = preferredRate
        }
    }

    func getPlayer() -> AVPlayer {
        return player
    }

    func setVideoInfo(subtitles: [VideoSubtitleEntity]) {
        subtitleManager.setExternalSubtitleInfo(subtitles: subtitles)
    }

    func setupPictureInPicture(with playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("[StreamingPlayerManager] PIP is not supported on this device")
            return
        }

        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        print("[StreamingPlayerManager] PIP controller initialized")
    }

    func getPIPController() -> AVPictureInPictureController? {
        return pipController
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("[StreamingPlayerManager] Audio session configured for playback")
        } catch {
            print("[StreamingPlayerManager] Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTimeSubject.send(time)
            self.subtitleManager.updateCurrentSubtitleIndex(time: time.seconds)
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        item.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    if let duration = self?.playerItem?.duration {
                        self?.durationSubject.send(duration)
                    }
                case .failed:
                    if let error = item.error {
                        self?.errorSubject.send(error.localizedDescription)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackLikelyToKeepUp, options: [.new])
            .sink { [weak self] isLikely in
                if !isLikely {
                    print("[StreamingPlayerManager] 버퍼링 중...")
                }
            }
            .store(in: &cancellables)
    }

    private func observePlayerStatus() {
        player.publisher(for: \.timeControlStatus, options: [.initial, .new])
            .sink { [weak self] status in
                let isPlaying = (status == .playing)
                self?.isPlayingSubject.send(isPlaying)
            }
            .store(in: &cancellables)
    }
}
