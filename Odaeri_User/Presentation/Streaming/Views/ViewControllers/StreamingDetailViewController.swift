//
//  StreamingDetailViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

final class StreamingDetailViewController: BaseViewController<StreamingDetailViewModel> {
    private let playerManager: StreamingPlayerManager

    private var playerLayer: AVPlayerLayer?
    private let controlView = PlayerControlView()

    private let fastForwardIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "2배속으로 재생 중"
        label.font = AppFont.body2
        label.textColor = AppColor.gray0
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    init(viewModel: StreamingDetailViewModel, playerManager: StreamingPlayerManager) {
        self.playerManager = playerManager
        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        setupCallbacks()
        viewDidLoadSubject.send(())
        hapticGenerator.prepare()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray100

        let player = playerManager.getPlayer()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        view.layer.addSublayer(layer)
        playerLayer = layer

        view.addSubview(controlView)
        view.addSubview(fastForwardIndicatorLabel)

        controlView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(60)
        }

        fastForwardIndicatorLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(150)
        }
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: view)
        let isRightSide = location.x > view.bounds.width / 2

        guard isRightSide else { return }

        switch gesture.state {
        case .began:
            playerManager.startFastForward()
            fastForwardIndicatorLabel.isHidden = false
            hapticGenerator.impactOccurred()
        case .ended, .cancelled:
            playerManager.stopFastForward()
            fastForwardIndicatorLabel.isHidden = true
        default:
            break
        }
    }

    private func setupCallbacks() {
        viewModel.onPlayPauseTriggered = { [weak self] in
            guard let self = self else { return }
            if self.playerManager.getPlayer().timeControlStatus == .playing {
                self.playerManager.pause()
            } else {
                self.playerManager.play()
            }
        }

        viewModel.onSeekRequested = { [weak self] time in
            self?.playerManager.seek(to: time)
        }
    }

    override func bind() {
        super.bind()

        let input = StreamingDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            playPauseTapped: controlView.playPauseTappedPublisher,
            seekToProgress: controlView.seekToProgressPublisher,
            settingsTapped: controlView.settingsTappedPublisher,
            currentTime: playerManager.currentTimePublisher,
            duration: playerManager.durationPublisher,
            isPlaying: playerManager.isPlayingPublisher
        )

        let output = viewModel.transform(input: input)

        output.streamURL
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.playerManager.loadVideo(url: url)
                self?.playerManager.play()
            }
            .store(in: &cancellables)

        output.currentTimeText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.controlView.updateCurrentTimeText(text)
            }
            .store(in: &cancellables)

        output.durationText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.controlView.updateDurationText(text)
            }
            .store(in: &cancellables)

        output.progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.controlView.updateProgress(progress)
            }
            .store(in: &cancellables)

        output.isPlayingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.controlView.updatePlayPauseButton(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        output.showSpeedSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speeds in
                self?.showSpeedSettingsAlert(speeds: speeds)
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)
    }

    private func showSpeedSettingsAlert(speeds: [Float]) {
        let alert = UIAlertController(title: "재생 속도", message: nil, preferredStyle: .actionSheet)

        for speed in speeds {
            let title = speed == 1.0 ? "일반 (1.0x)" : "\(speed)x"
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.playerManager.setPreferredRate(speed)
            }
            alert.addAction(action)
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancel)

        present(alert, animated: true)
    }
}
