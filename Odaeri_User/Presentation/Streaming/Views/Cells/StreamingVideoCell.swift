//
//  StreamingVideoCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import AVFoundation
import UIKit
import SnapKit
import Combine

final class StreamingVideoCell: BaseCollectionViewCell {
    static let reuseIdentifier = String(describing: StreamingVideoCell.self)

    let overlayView = StreamingOverlayView()
    var likeTapPublisher: AnyPublisher<LikeTapEvent, Never> {
        likeTapSubject.eraseToAnyPublisher()
    }

    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray100
        return view
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.progressTintColor = AppColor.brightForsythia
        view.trackTintColor = AppColor.gray45
        return view
    }()

    private let likeTapSubject = PassthroughSubject<LikeTapEvent, Never>()
    private var playerLayer: AVPlayerLayer?
    private weak var currentPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var currentDisplay: StreamingVideoDisplay?
    private weak var observedItem: AVPlayerItem?
    private var hasShownFirstFrame = false
    private var currentLikeState: Bool = false

    override func prepareForReuse() {
        super.prepareForReuse()
        removeTimeObserver()
        playerLayer?.player = nil
        currentPlayer = nil
        progressView.progress = 0
        overlayView.setDescriptionExpanded(false)
        currentDisplay = nil
        observedItem = nil
        hasShownFirstFrame = false
        currentLikeState = false
        thumbnailImageView.resetImage()
        thumbnailImageView.alpha = 1.0
        playerLayer?.opacity = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }

    func configure(display: StreamingVideoDisplay, player: AVPlayer) {
        currentDisplay = display
        currentLikeState = display.isLiked
        overlayView.configure(with: display)

        thumbnailImageView.setImage(
            url: display.thumbnailUrl,
            placeholder: nil,
            animated: false
        )
        thumbnailImageView.alpha = 1.0
        hasShownFirstFrame = false

        attachPlayer(player)
        configureTimeObserver(for: player)
        bindPlaybackStatus(for: player)
    }

    func updateLikeDisplay(isLiked: Bool, likeCountText: String) {
        currentLikeState = isLiked
        overlayView.updateLikeState(isLiked: isLiked, likeCountText: likeCountText)
    }

    override func setupUI() {
        contentView.backgroundColor = AppColor.gray100
        contentView.layer.masksToBounds = true

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(overlayView)
        contentView.addSubview(progressView)

        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(2)
        }

        overlayView.onLikeTapped = { [weak self] in
            self?.handleLikeTap()
        }
    }

    private func attachPlayer(_ player: AVPlayer) {
        currentPlayer = player
        if playerLayer == nil {
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.opacity = 0.0
            contentView.layer.insertSublayer(layer, above: thumbnailImageView.layer)
            playerLayer = layer
        } else {
            playerLayer?.player = player
            playerLayer?.opacity = 0.0
        }
        setNeedsLayout()
    }

    private func configureTimeObserver(for player: AVPlayer) {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            guard let duration = player.currentItem?.duration.seconds,
                  duration.isFinite, duration > 0 else {
                self.progressView.progress = 0
                return
            }
            let progress = Float(time.seconds / duration)
            self.progressView.setProgress(progress, animated: true)
        }
    }

    private func removeTimeObserver() {
        guard let token = timeObserverToken,
              let player = currentPlayer else { return }
        player.removeTimeObserver(token)
        timeObserverToken = nil
    }

    private func handleLikeTap() {
        guard let display = currentDisplay else { return }
        let newState = !currentLikeState
        currentLikeState = newState
        likeTapSubject.send(LikeTapEvent(videoId: display.videoId, newState: newState))
    }

    private func transitionToVideo() {
        guard !hasShownFirstFrame else { return }
        hasShownFirstFrame = true

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)

        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = 0.3
        fadeOutAnimation.fillMode = .forwards
        fadeOutAnimation.isRemovedOnCompletion = false

        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0.0
        fadeInAnimation.toValue = 1.0
        fadeInAnimation.duration = 0.3
        fadeInAnimation.fillMode = .forwards
        fadeInAnimation.isRemovedOnCompletion = false

        thumbnailImageView.layer.add(fadeOutAnimation, forKey: "fadeOut")
        playerLayer?.add(fadeInAnimation, forKey: "fadeIn")

        thumbnailImageView.layer.opacity = 0.0
        playerLayer?.opacity = 1.0

        CATransaction.commit()
    }

    private func bindPlaybackStatus(for player: AVPlayer) {
        player.publisher(for: \.currentItem, options: [.initial, .new])
            .sink { [weak self] item in
                guard let self = self else { return }
                guard let item = item else {
                    print("[Streaming] player item is nil")
                    return
                }
                if self.observedItem === item {
                    return
                }
                self.observedItem = item
                self.bindItemStatus(item)
            }
            .store(in: &cancellables)

        bindPlayerStatus(player)
    }

    private func bindItemStatus(_ item: AVPlayerItem) {
        item.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] status in
                switch status {
                case .unknown:
                    print("[Streaming] item status: unknown")
                case .readyToPlay:
                    print("[Streaming] item status: readyToPlay")
                    self?.transitionToVideo()
                case .failed:
                    if let error = item.error as NSError? {
                        let message = error.localizedDescription
                        let domain = error.domain
                        let code = error.code
                        print("[Streaming] item status: failed, error: \(message) (\(domain), \(code))")
                        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                            print("[Streaming] underlying error: \(underlying.localizedDescription) (\(underlying.domain), \(underlying.code))")
                        }
                    } else {
                        print("[Streaming] item status: failed, error: unknown")
                    }
                @unknown default:
                    print("[Streaming] item status: unknown default")
                }
            }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackBufferEmpty, options: [.initial, .new])
            .sink { isEmpty in
                print("[Streaming] buffer empty: \(isEmpty)")
            }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackLikelyToKeepUp, options: [.initial, .new])
            .sink { isLikely in
                print("[Streaming] likely to keep up: \(isLikely)")
            }
            .store(in: &cancellables)
    }

    private func bindPlayerStatus(_ player: AVPlayer) {
        player.publisher(for: \.timeControlStatus, options: [.initial, .new])
            .sink { status in
                switch status {
                case .paused:
                    print("[Streaming] player status: paused")
                case .playing:
                    print("[Streaming] player status: playing")
                case .waitingToPlayAtSpecifiedRate:
                    print("[Streaming] player status: waitingToPlayAtSpecifiedRate")
                @unknown default:
                    print("[Streaming] player status: unknown default")
                }
            }
            .store(in: &cancellables)

        if #available(iOS 16.0, *) {
            player.publisher(for: \.reasonForWaitingToPlay, options: [.initial, .new])
                .sink { reason in
                    let text = reason?.rawValue ?? "none"
                    print("[Streaming] waiting reason: \(text)")
                }
                .store(in: &cancellables)
        }
    }
}

extension StreamingVideoCell {
    struct LikeTapEvent: Hashable {
        let videoId: String
        let newState: Bool
    }
}
