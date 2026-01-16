//
//  CircularProgressView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/13/26.
//

import UIKit

final class CircularProgressView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private enum Layout {
        static let lineWidth: CGFloat = 4
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }

    func setProgress(_ value: Float) {
        let clamped = max(0, min(1, value))
        progressLayer.strokeEnd = CGFloat(clamped)
    }

    func setLineColor(_ color: UIColor) {
        progressLayer.strokeColor = color.cgColor
    }

    private func setupLayers() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        trackLayer.strokeColor = AppColor.gray30.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = Layout.lineWidth

        progressLayer.strokeColor = AppColor.brightForsythia.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = Layout.lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
    }

    private func updatePath() {
        let radius = min(bounds.width, bounds.height) / 2 - Layout.lineWidth
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
}
