//
//  LandscapeVideoViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

protocol LandscapeVideoViewControllerDelegate: AnyObject {
    func landscapeVideoViewControllerDidFinish(_ viewController: LandscapeVideoViewController, playerLayer: AVPlayerLayer)
    func getSourceVideoFrame() -> CGRect
}

final class LandscapeVideoViewController: BaseViewController<StreamingDetailViewModel> {
    override var navigationBarHidden: Bool { true }

    let videoContainerView = VideoContainerView()
    private let controlOverlayView = VideoControlOverlayView()
    private(set) var playerLayer: AVPlayerLayer?

    weak var delegate: LandscapeVideoViewControllerDelegate?
    private weak var playerManager: StreamingPlayerManager?
    private var currentStreamEntity: VideoStreamEntity?
    private var currentQualitySelection: QualitySelection = .auto

    private var originalCenter: CGPoint = .zero
    private var isDismissing = false
    private var isCurrentlyPlaying = false

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

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setLandscapeOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setPortraitOrientation()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .black

        view.addSubview(videoContainerView)
        videoContainerView.addSubview(controlOverlayView)
        view.addSubview(fastForwardIndicatorLabel)

        videoContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        controlOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fastForwardIndicatorLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(150)
        }

        controlOverlayView.setInitiallyHidden()

        setupDismissGesture()
        setupLongPressGesture()
    }

    private func setupDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    private func setupLongPressGesture() {
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
            playerManager?.startFastForward()
            fastForwardIndicatorLabel.isHidden = false
            hapticGenerator.impactOccurred()
        case .ended, .cancelled:
            playerManager?.stopFastForward()
            fastForwardIndicatorLabel.isHidden = true
        default:
            break
        }
    }

    @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            originalCenter = view.center
            isDismissing = false

        case .changed:
            if translation.y < 0 {
                return
            }

            let progress = translation.y / view.bounds.height
            let scale = max(0.8, 1.0 - progress * 0.2)
            let alpha = max(0.5, 1.0 - progress * 0.5)

            view.center = CGPoint(x: originalCenter.x, y: originalCenter.y + translation.y)
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)

        case .ended, .cancelled:
            let threshold: CGFloat = 150
            let shouldDismiss = translation.y > threshold || velocity.y > 1000

            if shouldDismiss {
                isDismissing = true
                handleClose()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                    self.view.center = self.originalCenter
                    self.view.transform = .identity
                    self.view.backgroundColor = .black
                }
            }

        default:
            break
        }
    }

    override func bind() {
        super.bind()

        let controlView = controlOverlayView.getControlView()

        controlView.fullscreenTappedPublisher
            .sink { [weak self] in
                self?.handleClose()
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
                self?.showSpeedSettingsAlert()
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.qualitySelectedPublisher
            .sink { [weak self] selection in
                self?.applyQualitySelection(selection)
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlOverlayView.centerPlayPauseTappedPublisher
            .sink { [weak self] in
                self?.togglePlayPause()
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlOverlayView.seekBackwardTappedPublisher
            .sink { [weak self] in
                self?.seekRelative(seconds: -10)
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlOverlayView.seekForwardTappedPublisher
            .sink { [weak self] in
                self?.seekRelative(seconds: 10)
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)
    }

    private func handleClose() {
        guard let playerLayer = playerLayer else {
            dismiss(animated: true)
            return
        }

        controlOverlayView.hide()

        delegate?.landscapeVideoViewControllerDidFinish(self, playerLayer: playerLayer)
        dismiss(animated: true)
    }

    func attachPlayerLayer(_ layer: AVPlayerLayer) {
        playerLayer = layer
        videoContainerView.attachPlayerLayer(layer)
    }

    func getControlOverlayView() -> VideoControlOverlayView {
        return controlOverlayView
    }

    func setPlayerManager(_ manager: StreamingPlayerManager) {
        self.playerManager = manager

        manager.isPlayingPublisher
            .sink { [weak self] isPlaying in
                self?.isCurrentlyPlaying = isPlaying
            }
            .store(in: &cancellables)
    }

    func setStreamEntity(_ streamEntity: VideoStreamEntity, selected: QualitySelection) {
        currentStreamEntity = streamEntity
        currentQualitySelection = selected
        let qualities = streamEntity.qualities.map { $0.quality }
        controlOverlayView.getControlView().updateQualityOptions(qualities, selected: selected)
    }

    private func togglePlayPause() {
        guard let playerManager = playerManager else { return }
        if isCurrentlyPlaying {
            playerManager.pause()
        } else {
            playerManager.play()
        }
    }

    private func seekRelative(seconds: Double) {
        guard let playerManager = playerManager else { return }
        let player = playerManager.getPlayer()
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))

        guard let duration = player.currentItem?.duration else { return }

        let clampedTime: CMTime
        if newTime < .zero {
            clampedTime = .zero
        } else if newTime > duration {
            clampedTime = duration
        } else {
            clampedTime = newTime
        }

        playerManager.seek(to: clampedTime)
    }

    private func showSpeedSettingsAlert() {
        let speeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        let alert = UIAlertController(title: "재생 속도", message: nil, preferredStyle: .actionSheet)

        for speed in speeds {
            let title = speed == 1.0 ? "일반 (1.0x)" : "\(speed)x"
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.playerManager?.setPreferredRate(speed)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func applyQualitySelection(_ selection: QualitySelection) {
        guard let streamEntity = currentStreamEntity,
              let playerManager = playerManager else { return }
        guard selection != currentQualitySelection else { return }
        currentQualitySelection = selection

        let urlString: String
        switch selection {
        case .auto:
            urlString = streamEntity.streamUrl
        case .manual(let quality):
            urlString = streamEntity.qualities.first(where: { $0.quality == quality })?.url ?? streamEntity.streamUrl
        }

        guard let url = URL(string: urlString) else { return }
        let currentTime = playerManager.getPlayer().currentTime()
        playerManager.loadVideo(url: url)
        playerManager.seek(to: currentTime) { [weak self] in
            self?.playerManager?.play()
        }
    }

    private func setLandscapeOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                print("Orientation update error: \(error.localizedDescription)")
            }
        } else {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }

    private func setPortraitOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                print("Orientation update error: \(error.localizedDescription)")
            }
        } else {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGesture.translation(in: view)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }
}
