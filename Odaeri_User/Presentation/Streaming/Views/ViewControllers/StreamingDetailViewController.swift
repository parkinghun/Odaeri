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

    private let videoContainerView = VideoContainerView()
    private let controlOverlayView = VideoControlOverlayView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = AppColor.gray0
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.numberOfLines = 0
        return label
    }()

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
        videoContainerView.playerLayer?.frame = videoContainerView.bounds
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0

        view.addSubview(videoContainerView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)

        let player = playerManager.getPlayer()
        let layer = AVPlayerLayer(player: player)
        videoContainerView.attachPlayerLayer(layer)

        videoContainerView.addSubview(controlOverlayView)
        videoContainerView.addSubview(fastForwardIndicatorLabel)

        videoContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(videoContainerView.snp.width).multipliedBy(9.0 / 16.0)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(videoContainerView.snp.bottom)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }

        controlOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fastForwardIndicatorLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(150)
        }
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPress)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        videoContainerView.addGestureRecognizer(panGesture)
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

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: videoContainerView)
        let velocity = gesture.velocity(in: videoContainerView)

        switch gesture.state {
        case .changed:
            if translation.y < 0 {
                return
            }
        case .ended:
            let threshold: CGFloat = 100
            let shouldEnterFullscreen = translation.y < -threshold || velocity.y < -1000

            if shouldEnterFullscreen {
                enterFullscreen()
            }
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

        let controlView = controlOverlayView.getControlView()

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
                self?.controlOverlayView.getControlView().updateCurrentTimeText(text)
            }
            .store(in: &cancellables)

        output.durationText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.controlOverlayView.getControlView().updateDurationText(text)
            }
            .store(in: &cancellables)

        output.progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.controlOverlayView.getControlView().updateProgress(progress)
            }
            .store(in: &cancellables)

        output.isPlayingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.controlOverlayView.getControlView().updatePlayPauseButton(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        output.showSpeedSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speeds in
                self?.showSpeedSettingsAlert(speeds: speeds)
            }
            .store(in: &cancellables)

        controlView.playPauseTappedPublisher
            .sink { [weak self] in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.seekToProgressPublisher
            .sink { [weak self] _ in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.settingsTappedPublisher
            .sink { [weak self] in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.fullscreenTappedPublisher
            .sink { [weak self] in
                self?.enterFullscreen()
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)

        output.title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.titleLabel.text = title
            }
            .store(in: &cancellables)

        output.description
            .receive(on: DispatchQueue.main)
            .sink { [weak self] description in
                self?.descriptionLabel.text = description
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

    private func enterFullscreen() {
        guard let playerLayer = videoContainerView.detachPlayerLayer() else { return }

        let landscapeVC = LandscapeVideoViewController(viewModel: viewModel)
        landscapeVC.delegate = self
        landscapeVC.modalPresentationStyle = .custom
        landscapeVC.transitioningDelegate = self

        landscapeVC.loadViewIfNeeded()
        landscapeVC.attachPlayerLayer(playerLayer)

        let landscapeControlView = landscapeVC.getControlOverlayView().getControlView()
        bindControlViewToViewModel(landscapeControlView)
        bindViewModelOutputToControlView(landscapeControlView)

        present(landscapeVC, animated: true)
    }

    private func exitFullscreen(playerLayer: AVPlayerLayer) {
        videoContainerView.attachPlayerLayer(playerLayer)

        let controlView = controlOverlayView.getControlView()
        bindControlViewToViewModel(controlView)
    }

    private func bindControlViewToViewModel(_ controlView: PlayerControlView) {
        controlView.playPauseTappedPublisher
            .sink { [weak self] in
                self?.viewModel.onPlayPauseTriggered?()
            }
            .store(in: &cancellables)

        controlView.settingsTappedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                let speeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                self.showSpeedSettingsAlert(speeds: speeds)
            }
            .store(in: &cancellables)
    }

    private func bindViewModelOutputToControlView(_ controlView: PlayerControlView) {
        let input = StreamingDetailViewModel.Input(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            playPauseTapped: Empty().eraseToAnyPublisher(),
            seekToProgress: Empty().eraseToAnyPublisher(),
            settingsTapped: Empty().eraseToAnyPublisher(),
            currentTime: playerManager.currentTimePublisher,
            duration: playerManager.durationPublisher,
            isPlaying: playerManager.isPlayingPublisher
        )

        let output = viewModel.transform(input: input)

        output.currentTimeText
            .receive(on: DispatchQueue.main)
            .sink { text in
                controlView.updateCurrentTimeText(text)
            }
            .store(in: &cancellables)

        output.durationText
            .receive(on: DispatchQueue.main)
            .sink { text in
                controlView.updateDurationText(text)
            }
            .store(in: &cancellables)

        output.progress
            .receive(on: DispatchQueue.main)
            .sink { progress in
                controlView.updateProgress(progress)
            }
            .store(in: &cancellables)

        output.isPlayingState
            .receive(on: DispatchQueue.main)
            .sink { isPlaying in
                controlView.updatePlayPauseButton(isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }
}

extension StreamingDetailViewController: LandscapeVideoViewControllerDelegate {
    func landscapeVideoViewControllerDidFinish(_ viewController: LandscapeVideoViewController, playerLayer: AVPlayerLayer) {
        exitFullscreen(playerLayer: playerLayer)
    }

    func getSourceVideoFrame() -> CGRect {
        return videoContainerView.convert(videoContainerView.bounds, to: nil)
    }
}

extension StreamingDetailViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let landscapeVC = presented as? LandscapeVideoViewController else { return nil }
        return FullscreenTransitionAnimator(
            isPresenting: true,
            sourceViewController: self,
            destinationViewController: landscapeVC
        )
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FullscreenTransitionAnimator(
            isPresenting: false,
            sourceViewController: self
        )
    }
}
