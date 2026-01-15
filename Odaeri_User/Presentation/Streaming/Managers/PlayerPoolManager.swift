//
//  PlayerPoolManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation
import Foundation

final class PlayerPoolManager {
    enum PreferredQuality {
        case low
        case medium
        case high
    }

    private enum Constant {
        static let poolSize = 3
        static let prefetchTimeout: TimeInterval = 10
        static let lowQualityBufferDuration: TimeInterval = 0.5
        static let mediumQualityBufferDuration: TimeInterval = 1.0
        static let highQualityBufferDuration: TimeInterval = 2.0
    }

    var onTokenExpiration: ((String, CMTime, Int) -> Void)?

    private let mediaProvider: MediaProviding
    private let syncQueue = DispatchQueue(label: "com.odaeri.playerpool.sync")
    private var players: [AVPlayer]
    private var playerAssignments: [Int: String] = [:]
    private var indexAssignments: [String: Int] = [:]
    private var assetCache: [String: AVAsset] = [:]
    private var prefetchTasks: [String: URLSessionDataTask] = [:]
    private var preferredQuality: PreferredQuality = .high
    private var playerItemObservers: [String: NSKeyValueObservation] = [:]

    init(mediaProvider: MediaProviding = UnifiedMediaProvider()) {
        self.mediaProvider = mediaProvider
        self.players = (0..<Constant.poolSize).map { _ in AVPlayer() }
        setupAudioSession()
    }

    func player(for index: Int) -> AVPlayer {
        players[playerIndex(for: index)]
    }

    func preparePlayer(for index: Int, video: VideoEntity, stream: VideoStreamEntity?) {
        let poolIndex = playerIndex(for: index)
        let player = players[poolIndex]

        if assignedVideoId(for: poolIndex) == video.videoId {
            return
        }

        guard let asset = makeAsset(for: video, stream: stream) else { return }
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = bufferDuration(for: preferredQuality)
        player.replaceCurrentItem(with: item)
        setAssignedVideoId(video.videoId, for: poolIndex)
        setIndexAssignment(index, for: video.videoId)
        observePlayerItemStatus(item, videoId: video.videoId, player: player, index: index)
    }

    func setPreferredQuality(_ quality: PreferredQuality) {
        preferredQuality = quality

        for (index, player) in players.enumerated() {
            guard let currentItem = player.currentItem else { continue }
            currentItem.preferredForwardBufferDuration = bufferDuration(for: quality)

            if index != playerIndex(for: 0) {
                player.isMuted = true
            }
        }
    }

    func prefetchPlaylist(for video: VideoEntity, stream: VideoStreamEntity?) {
        guard video.videoType == .hls,
              let urlString = stream?.streamUrl,
              let url = URL(string: urlString) else { return }

        if hasPrefetchTask(for: video.videoId) {
            return
        }

        let request = URLRequest(url: url, timeoutInterval: Constant.prefetchTimeout)

        let task = URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            self?.removePrefetchTask(for: video.videoId)
        }
        setPrefetchTask(task, for: video.videoId)
        task.resume()
    }

    func cleanup(keepingVideoIds: Set<String>) {
        for (index, player) in players.enumerated() {
            guard let assigned = assignedVideoId(for: index),
                  !keepingVideoIds.contains(assigned) else { continue }
            player.replaceCurrentItem(with: nil)
            removeAssignedVideoId(for: index)
        }

        let removableKeys = cachedAssetKeys(excluding: keepingVideoIds)
        removableKeys.forEach { removeCachedAsset(for: $0) }
    }

    func pauseAll() {
        players.forEach { $0.pause() }
    }

    func resume(index: Int) {
        let player = player(for: index)
        if player.timeControlStatus != .playing {
            player.play()
        }
    }

    func switchQuality(
        videoId: String,
        qualityURL: URL,
        autoplay: Bool
    ) {
        guard let poolIndex = assignedPoolIndex(for: videoId) else { return }
        let player = players[poolIndex]
        let currentTime = player.currentTime()
        let isPlaying = player.timeControlStatus == .playing

        guard let asset = mediaProvider.makeAsset(for: qualityURL) else { return }
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = bufferDuration(for: preferredQuality)
        player.replaceCurrentItem(with: item)
        player.appliesMediaSelectionCriteriaAutomatically = false
        player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if autoplay || isPlaying {
                player.play()
            }
        }
        cacheAsset(asset, for: videoId)
    }

    func resumeFromTokenExpiration(videoId: String, stream: VideoStreamEntity, seekTo time: CMTime, index: Int) {
        guard let poolIndex = assignedPoolIndex(for: videoId) else {
            print("[PlayerPoolManager] Resume 실패: poolIndex를 찾을 수 없음")
            return
        }

        let player = players[poolIndex]
        let wasPlaying = player.timeControlStatus == .playing

        guard let url = URL(string: stream.streamUrl),
              let asset = mediaProvider.makeAsset(for: url) else {
            print("[PlayerPoolManager] Resume 실패: asset 생성 실패")
            return
        }

        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = bufferDuration(for: preferredQuality)
        player.replaceCurrentItem(with: item)
        cacheAsset(asset, for: videoId)
        observePlayerItemStatus(item, videoId: videoId, player: player, index: index)

        print("[PlayerPoolManager] 토큰 재발급 후 \(time.seconds)초 위치로 이동")
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            if finished && wasPlaying {
                player.play()
                print("[PlayerPoolManager] 재생 재개")
            }
        }
    }

    private func makeAsset(for video: VideoEntity, stream: VideoStreamEntity?) -> AVAsset? {
        if let cached = cachedAsset(for: video.videoId) {
            return cached
        }
        guard let asset = mediaProvider.makeAsset(for: video, stream: stream) else { return nil }
        cacheAsset(asset, for: video.videoId)
        return asset
    }

    private func playerIndex(for index: Int) -> Int {
        guard index >= 0 else { return 0 }
        return index % Constant.poolSize
    }

    private func bufferDuration(for quality: PreferredQuality) -> TimeInterval {
        switch quality {
        case .low:
            return Constant.lowQualityBufferDuration
        case .medium:
            return Constant.mediumQualityBufferDuration
        case .high:
            return Constant.highQualityBufferDuration
        }
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)
            print("[PlayerPoolManager] 오디오 세션 설정 완료")
        } catch {
            print("[PlayerPoolManager] 오디오 세션 설정 실패: \(error)")
        }
    }

    private func observePlayerItemStatus(_ item: AVPlayerItem, videoId: String, player: AVPlayer, index: Int) {
        let observer = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }

            switch item.status {
            case .readyToPlay:
                print("[PlayerPoolManager] 재생 준비 완료: \(videoId)")
                if let duration = item.asset.duration.seconds.isFinite ? item.asset.duration.seconds : nil {
                    print("[PlayerPoolManager] 영상 길이: \(Int(duration))초")
                }
            case .failed:
                print("[PlayerPoolManager] 재생 실패: \(videoId)")
                if let error = item.error as NSError? {
                    print("[PlayerPoolManager] 에러: \(error.localizedDescription)")
                    let code = error.code
                    let domain = error.domain

                    if code == -1008 || code == 403 || code == 419 {
                        print("[PlayerPoolManager] 토큰 만료 감지 (code: \(code)): \(videoId)")
                        let currentTime = player.currentTime()
                        StreamURLCache.shared.remove(for: videoId)
                        self.removeCachedAsset(for: videoId)

                        DispatchQueue.main.async {
                            self.onTokenExpiration?(videoId, currentTime, index)
                        }
                    }
                }
            case .unknown:
                print("[PlayerPoolManager] 상태 알 수 없음: \(videoId)")
            @unknown default:
                break
            }
        }

        syncQueue.async(flags: .barrier) { [weak self] in
            self?.playerItemObservers[videoId] = observer
        }
    }
}

private extension PlayerPoolManager {
    func assignedVideoId(for index: Int) -> String? {
        syncQueue.sync {
            playerAssignments[index]
        }
    }

    func setAssignedVideoId(_ videoId: String, for index: Int) {
        syncQueue.sync {
            playerAssignments[index] = videoId
        }
    }

    func removeAssignedVideoId(for index: Int) {
        syncQueue.sync {
            playerAssignments.removeValue(forKey: index)
        }
    }

    func assignedPoolIndex(for videoId: String) -> Int? {
        syncQueue.sync {
            playerAssignments.first(where: { $0.value == videoId })?.key
        }
    }

    func cachedAsset(for videoId: String) -> AVAsset? {
        syncQueue.sync {
            assetCache[videoId]
        }
    }

    func cacheAsset(_ asset: AVAsset, for videoId: String) {
        syncQueue.sync {
            assetCache[videoId] = asset
        }
    }

    func cachedAssetKeys(excluding keepIds: Set<String>) -> [String] {
        syncQueue.sync {
            assetCache.keys.filter { !keepIds.contains($0) }
        }
    }

    func removeCachedAsset(for videoId: String) {
        syncQueue.sync {
            assetCache.removeValue(forKey: videoId)
        }
    }

    func hasPrefetchTask(for videoId: String) -> Bool {
        syncQueue.sync {
            prefetchTasks[videoId] != nil
        }
    }

    func setPrefetchTask(_ task: URLSessionDataTask, for videoId: String) {
        syncQueue.sync {
            prefetchTasks[videoId] = task
        }
    }

    func removePrefetchTask(for videoId: String) {
        syncQueue.sync {
            prefetchTasks.removeValue(forKey: videoId)
        }
    }

    func setIndexAssignment(_ index: Int, for videoId: String) {
        syncQueue.sync {
            indexAssignments[videoId] = index
        }
    }

    func getIndexAssignment(for videoId: String) -> Int? {
        syncQueue.sync {
            indexAssignments[videoId]
        }
    }
}
