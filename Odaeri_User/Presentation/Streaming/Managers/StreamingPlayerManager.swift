//
//  StreamingPlayerManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import AVFoundation
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

    private let currentTimeSubject = PassthroughSubject<CMTime, Never>()
    private let durationSubject = PassthroughSubject<CMTime, Never>()
    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let currentRateSubject = CurrentValueSubject<Float, Never>(1.0)

    private var preferredRate: Float = 1.0
    private var isFastForwarding = false

    private(set) lazy var subtitleManager: SubtitleManager = {
        return SubtitleManager(player: player)
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

    init() {
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
        player.rate = isFastForwarding ? 2.0 : preferredRate
        isPlayingSubject.send(true)
    }

    func pause() {
        player.pause()
        isPlayingSubject.send(false)
    }

    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
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

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTimeSubject.send(time)
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
