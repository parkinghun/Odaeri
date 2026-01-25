//
//  VideoControlOverlayView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit
import Combine
import SnapKit

final class VideoControlOverlayView: BaseView {
    private let controlView = PlayerControlView()

    private let centerPlayPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .thin)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        return button
    }()

    private let seekBackwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .thin)
        button.setImage(UIImage(systemName: "gobackward.10", withConfiguration: config), for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        return button
    }()

    private let seekForwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .thin)
        button.setImage(UIImage(systemName: "goforward.10", withConfiguration: config), for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        return button
    }()

    let centerPlayPauseTappedPublisher: AnyPublisher<Void, Never>
    let seekBackwardTappedPublisher: AnyPublisher<Void, Never>
    let seekForwardTappedPublisher: AnyPublisher<Void, Never>

    private var cancellables = Set<AnyCancellable>()
    private var hideTimer: Timer?
    private let autoHideDelay: TimeInterval = 3.0

    private var isVisible = true {
        didSet {
            updateVisibility(animated: true)
            onVisibilityChanged?(isVisible)
        }
    }

    var onControlTapped: (() -> Void)?
    var onVisibilityChanged: ((Bool) -> Void)?

    override init(frame: CGRect) {
        centerPlayPauseTappedPublisher = centerPlayPauseButton.tapPublisher().eraseToAnyPublisher()
        seekBackwardTappedPublisher = seekBackwardButton.tapPublisher().eraseToAnyPublisher()
        seekForwardTappedPublisher = seekForwardButton.tapPublisher().eraseToAnyPublisher()
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        addSubview(controlView)
        addSubview(centerPlayPauseButton)
        addSubview(seekBackwardButton)
        addSubview(seekForwardButton)

        controlView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(60)
        }

        centerPlayPauseButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(60)
        }

        seekBackwardButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(centerPlayPauseButton.snp.leading).offset(-30)
            make.width.height.equalTo(50)
        }

        seekForwardButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(centerPlayPauseButton.snp.trailing).offset(30)
            make.width.height.equalTo(50)
        }

        setupTapGesture()
        scheduleAutoHide()
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        toggleVisibility()
        onControlTapped?()
    }

    func toggleVisibility() {
        isVisible.toggle()

        if isVisible {
            scheduleAutoHide()
        } else {
            cancelAutoHide()
        }
    }

    func show() {
        guard !isVisible else { return }
        isVisible = true
        scheduleAutoHide()
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        cancelAutoHide()
    }

    func resetAutoHideTimer() {
        guard isVisible else { return }
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        cancelAutoHide()

        hideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    private func cancelAutoHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func updateVisibility(animated: Bool) {
        let animations = {
            self.controlView.alpha = self.isVisible ? 1.0 : 0.0
            self.centerPlayPauseButton.alpha = self.isVisible ? 1.0 : 0.0
            self.seekBackwardButton.alpha = self.isVisible ? 1.0 : 0.0
            self.seekForwardButton.alpha = self.isVisible ? 1.0 : 0.0
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: animations)
        } else {
            animations()
        }
    }

    func getControlView() -> PlayerControlView {
        return controlView
    }

    func setInitiallyHidden() {
        isVisible = false
        controlView.alpha = 0
        centerPlayPauseButton.alpha = 0
        seekBackwardButton.alpha = 0
        seekForwardButton.alpha = 0
        cancelAutoHide()
    }

    func updateCenterPlayPauseButton(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .thin)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        centerPlayPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }

    deinit {
        cancelAutoHide()
    }
}

extension VideoControlOverlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == centerPlayPauseButton || touch.view == seekBackwardButton || touch.view == seekForwardButton {
            return false
        }
        if touch.view is UIButton || touch.view is UISlider {
            return false
        }
        return true
    }
}
