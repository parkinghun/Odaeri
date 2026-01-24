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

    private var originalCenter: CGPoint = .zero
    private var isDismissing = false

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

        videoContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        controlOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        controlOverlayView.setInitiallyHidden()

        setupDismissGesture()
    }

    private func setupDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
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
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.subtitleTappedPublisher
            .sink { [weak self] in
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
}
