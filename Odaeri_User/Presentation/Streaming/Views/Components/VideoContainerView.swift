//
//  VideoContainerView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit
import AVFoundation

final class VideoContainerView: UIView {

    private(set) var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray100
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func attachPlayerLayer(_ layer: AVPlayerLayer) {
        playerLayer?.removeFromSuperlayer()
        playerLayer = layer
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
    }

    func detachPlayerLayer() -> AVPlayerLayer? {
        guard let layer = playerLayer else { return nil }
        layer.removeFromSuperlayer()
        playerLayer = nil
        return layer
    }
}
