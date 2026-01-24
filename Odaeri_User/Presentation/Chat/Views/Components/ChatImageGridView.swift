//
//  ChatImageGridView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import UIKit

final class ChatImageGridView: UIView {
    var onImageTapped: ((Int) -> Void)?
    var onRetryTapped: (() -> Void)?

    private var imageViews: [UIImageView] = []
    private let overlayView = UIView()
    private let progressView = CircularProgressView()
    private let retryButton = UIButton(type: .system)

    private var currentImageCount = 0

    private enum Layout {
        static let viewCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 0.5
        static let spacing: CGFloat = 2
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        createImageViewPool()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        with urls: [String],
        status: ChatMessageStatus = .sent,
        progress: Float? = nil
    ) {
        guard !urls.isEmpty, urls.count <= 5 else { return }

        currentImageCount = urls.count
        hideAllImageViews()

        for (index, url) in urls.enumerated() {
            guard index < imageViews.count else { break }
            let imageView = imageViews[index]
            imageView.isHidden = false
            imageView.setImage(
                url: url,
                placeholder: nil,
                animated: true,
                downsample: true
            )
        }

        updateOverlay(status: status, progress: progress)
        setNeedsLayout()
    }

    private func layoutSingleImage(width: CGFloat, height: CGFloat) {
        imageViews[0].frame = CGRect(x: 0, y: 0, width: width, height: height)
    }

    private func layoutTwoImages(width: CGFloat, height: CGFloat, spacing: CGFloat) {
        let halfWidth = (width - spacing) / 2

        imageViews[0].frame = CGRect(x: 0, y: 0, width: halfWidth, height: height)
        imageViews[1].frame = CGRect(x: halfWidth + spacing, y: 0, width: halfWidth, height: height)
    }

    private func layoutThreeImages(width: CGFloat, height: CGFloat, spacing: CGFloat) {
        let halfWidth = (width - spacing) / 2
        let halfHeight = (height - spacing) / 2

        imageViews[0].frame = CGRect(x: 0, y: 0, width: halfWidth, height: height)
        imageViews[1].frame = CGRect(x: halfWidth + spacing, y: 0, width: halfWidth, height: halfHeight)
        imageViews[2].frame = CGRect(x: halfWidth + spacing, y: halfHeight + spacing, width: halfWidth, height: halfHeight)
    }

    private func layoutFourImages(width: CGFloat, height: CGFloat, spacing: CGFloat) {
        let halfWidth = (width - spacing) / 2
        let halfHeight = (height - spacing) / 2

        imageViews[0].frame = CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight)
        imageViews[1].frame = CGRect(x: halfWidth + spacing, y: 0, width: halfWidth, height: halfHeight)
        imageViews[2].frame = CGRect(x: 0, y: halfHeight + spacing, width: halfWidth, height: halfHeight)
        imageViews[3].frame = CGRect(x: halfWidth + spacing, y: halfHeight + spacing, width: halfWidth, height: halfHeight)
    }

    private func layoutFiveImages(width: CGFloat, height: CGFloat, spacing: CGFloat) {
        let halfHeight = (height - spacing) / 2
        let topThirdWidth = (width - spacing * 2) / 3
        let bottomHalfWidth = (width - spacing) / 2

        imageViews[0].frame = CGRect(x: 0, y: 0, width: topThirdWidth, height: halfHeight)
        imageViews[1].frame = CGRect(x: topThirdWidth + spacing, y: 0, width: topThirdWidth, height: halfHeight)
        imageViews[2].frame = CGRect(x: (topThirdWidth + spacing) * 2, y: 0, width: topThirdWidth, height: halfHeight)
        imageViews[3].frame = CGRect(x: 0, y: halfHeight + spacing, width: bottomHalfWidth, height: halfHeight)
        imageViews[4].frame = CGRect(x: bottomHalfWidth + spacing, y: halfHeight + spacing, width: bottomHalfWidth, height: halfHeight)
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = Layout.viewCornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = AppColor.gray30.cgColor
        backgroundColor = AppColor.gray15

        addSubview(overlayView)

        overlayView.backgroundColor = AppColor.gray100.withAlphaComponent(0.35)
        overlayView.isHidden = true

        overlayView.addSubview(progressView)
        overlayView.addSubview(retryButton)

        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = AppColor.errorRed
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width
        let height = bounds.height
        let spacing = Layout.spacing

        switch currentImageCount {
        case 1:
            layoutSingleImage(width: width, height: height)

        case 2:
            layoutTwoImages(width: width, height: height, spacing: spacing)

        case 3:
            layoutThreeImages(width: width, height: height, spacing: spacing)

        case 4:
            layoutFourImages(width: width, height: height, spacing: spacing)

        case 5:
            layoutFiveImages(width: width, height: height, spacing: spacing)

        default:
            break
        }

        overlayView.frame = bounds

        let progressSize: CGFloat = 44
        progressView.frame = CGRect(
            x: (width - progressSize) / 2,
            y: (height - progressSize) / 2,
            width: progressSize,
            height: progressSize
        )

        let retrySize: CGFloat = 36
        retryButton.frame = CGRect(
            x: (width - retrySize) / 2,
            y: (height - retrySize) / 2,
            width: retrySize,
            height: retrySize
        )
    }

    private func createImageViewPool() {
        for index in 0..<5 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = AppColor.gray15
            imageView.isUserInteractionEnabled = true
            imageView.isHidden = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            imageView.addGestureRecognizer(tapGesture)
            imageView.tag = index

            addSubview(imageView)
            imageViews.append(imageView)
        }
    }

    @objc private func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? UIImageView else { return }
        let index = tappedView.tag
        onImageTapped?(index)
    }

    private func hideAllImageViews() {
        imageViews.forEach { $0.isHidden = true }
    }

    private func updateOverlay(status: ChatMessageStatus, progress: Float?) {
        switch status {
        case .sending:
            overlayView.isHidden = false
            retryButton.isHidden = true
            progressView.isHidden = false
            progressView.setLineColor(AppColor.brightForsythia)
            progressView.setProgress(progress ?? 0)
        case .failed:
            overlayView.isHidden = false
            retryButton.isHidden = false
            progressView.isHidden = true
        case .sent:
            overlayView.isHidden = true
        }
    }

    @objc private func handleRetryTap() {
        onRetryTapped?()
    }
}
