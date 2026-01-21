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

    private var hideTimer: Timer?
    private let autoHideDelay: TimeInterval = 3.0

    private var isVisible = true {
        didSet {
            updateVisibility(animated: true)
        }
    }

    var onControlTapped: (() -> Void)?

    override func setupView() {
        addSubview(controlView)

        controlView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(60)
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

    deinit {
        cancelAutoHide()
    }
}

extension VideoControlOverlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton || touch.view is UISlider {
            return false
        }
        return true
    }
}
