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

    private var case1Constraints: [NSLayoutConstraint] = []
    private var case2Constraints: [NSLayoutConstraint] = []
    private var case3Constraints: [NSLayoutConstraint] = []
    private var case4Constraints: [NSLayoutConstraint] = []
    private var case5Constraints: [NSLayoutConstraint] = []

    private var activeConstraints: [NSLayoutConstraint] = []

    private enum Layout {
        static let viewCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 0.5
        static let spacing: CGFloat = AppSpacing.tiny
        static let singleImageMaxHeight: CGFloat = 300
        static let singleImageMinHeight: CGFloat = 150
        static let defaultAspectRatio: CGFloat = 4.0 / 3.0
        static let maxContentWidth: CGFloat = UIScreen.main.bounds.width * 0.7

        static var unitSize: CGFloat {
            return (maxContentWidth - spacing) / 2
        }

        static var smallUnitSize: CGFloat {
            return (maxContentWidth - spacing * 2) / 3
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        createImageViewPool()
        setupAllConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        with urls: [String],
        aspectRatio: CGFloat? = nil,
        status: ChatMessageStatus = .sent,
        progress: Float? = nil
    ) {
        guard !urls.isEmpty, urls.count <= 5 else { return }

        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()

        hideAllImageViews()

        for (index, url) in urls.enumerated() {
            let imageView = imageViews[index]
            imageView.isHidden = false
            imageView.setImage(
                url: url,
                placeholder: nil,
                animated: true,
                downsample: true
            )
        }

        activateConstraints(for: urls.count, aspectRatio: aspectRatio)
        updateOverlay(status: status, progress: progress)
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = Layout.viewCornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = AppColor.gray30.cgColor
        backgroundColor = AppColor.gray15

        addSubview(overlayView)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        overlayView.backgroundColor = AppColor.gray100.withAlphaComponent(0.35)
        overlayView.isHidden = true

        overlayView.addSubview(progressView)
        overlayView.addSubview(retryButton)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 44),
            progressView.heightAnchor.constraint(equalToConstant: 44),

            retryButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 36),
            retryButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = AppColor.errorRed
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
    }

    private func createImageViewPool() {
        for index in 0..<5 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = AppColor.gray15
            imageView.isUserInteractionEnabled = true
            imageView.isHidden = true
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            imageView.addGestureRecognizer(tapGesture)
            imageView.tag = index

            addSubview(imageView)
            imageViews.append(imageView)
        }
    }

    private func setupAllConstraints() {
        setupCase1Constraints()
        setupCase2Constraints()
        setupCase3Constraints()
        setupCase4Constraints()
        setupCase5Constraints()
    }

    private func setupCase1Constraints() {
        let imageView = imageViews[0]

        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: Layout.maxContentWidth)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: Layout.maxContentWidth / Layout.defaultAspectRatio)
        let topConstraint = imageView.topAnchor.constraint(equalTo: topAnchor)
        let leadingConstraint = imageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let bottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let trailingConstraint = imageView.trailingAnchor.constraint(equalTo: trailingAnchor)

        case1Constraints = [widthConstraint, heightConstraint, topConstraint, leadingConstraint, bottomConstraint, trailingConstraint]
    }

    private func setupCase2Constraints() {
        let imageView0 = imageViews[0]
        let imageView1 = imageViews[1]
        let unitSize = Layout.unitSize

        case2Constraints = [
            imageView0.topAnchor.constraint(equalTo: topAnchor),
            imageView0.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView0.widthAnchor.constraint(equalToConstant: unitSize),
            imageView0.heightAnchor.constraint(equalToConstant: unitSize),
            imageView0.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView1.topAnchor.constraint(equalTo: topAnchor),
            imageView1.leadingAnchor.constraint(equalTo: imageView0.trailingAnchor, constant: Layout.spacing),
            imageView1.widthAnchor.constraint(equalToConstant: unitSize),
            imageView1.heightAnchor.constraint(equalToConstant: unitSize),
            imageView1.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView1.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    private func setupCase3Constraints() {
        let imageView0 = imageViews[0]
        let imageView1 = imageViews[1]
        let imageView2 = imageViews[2]
        let unitSize = Layout.unitSize
        let totalHeight = unitSize * 2 + Layout.spacing

        case3Constraints = [
            imageView0.topAnchor.constraint(equalTo: topAnchor),
            imageView0.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView0.widthAnchor.constraint(equalToConstant: unitSize),
            imageView0.heightAnchor.constraint(equalToConstant: totalHeight),
            imageView0.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView1.topAnchor.constraint(equalTo: topAnchor),
            imageView1.leadingAnchor.constraint(equalTo: imageView0.trailingAnchor, constant: Layout.spacing),
            imageView1.widthAnchor.constraint(equalToConstant: unitSize),
            imageView1.heightAnchor.constraint(equalToConstant: unitSize),
            imageView1.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView2.topAnchor.constraint(equalTo: imageView1.bottomAnchor, constant: Layout.spacing),
            imageView2.leadingAnchor.constraint(equalTo: imageView0.trailingAnchor, constant: Layout.spacing),
            imageView2.widthAnchor.constraint(equalToConstant: unitSize),
            imageView2.heightAnchor.constraint(equalToConstant: unitSize),
            imageView2.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView2.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    private func setupCase4Constraints() {
        let imageView0 = imageViews[0]
        let imageView1 = imageViews[1]
        let imageView2 = imageViews[2]
        let imageView3 = imageViews[3]
        let unitSize = Layout.unitSize
        let totalHeight = unitSize * 2 + Layout.spacing

        case4Constraints = [
            imageView0.topAnchor.constraint(equalTo: topAnchor),
            imageView0.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView0.widthAnchor.constraint(equalToConstant: unitSize),
            imageView0.heightAnchor.constraint(equalToConstant: unitSize),

            imageView1.topAnchor.constraint(equalTo: topAnchor),
            imageView1.leadingAnchor.constraint(equalTo: imageView0.trailingAnchor, constant: Layout.spacing),
            imageView1.widthAnchor.constraint(equalToConstant: unitSize),
            imageView1.heightAnchor.constraint(equalToConstant: unitSize),
            imageView1.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView2.topAnchor.constraint(equalTo: imageView0.bottomAnchor, constant: Layout.spacing),
            imageView2.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView2.widthAnchor.constraint(equalToConstant: unitSize),
            imageView2.heightAnchor.constraint(equalToConstant: unitSize),
            imageView2.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView3.topAnchor.constraint(equalTo: imageView1.bottomAnchor, constant: Layout.spacing),
            imageView3.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: Layout.spacing),
            imageView3.widthAnchor.constraint(equalToConstant: unitSize),
            imageView3.heightAnchor.constraint(equalToConstant: unitSize),
            imageView3.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView3.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(equalToConstant: Layout.maxContentWidth),
            heightAnchor.constraint(equalToConstant: totalHeight)
        ]
    }

    private func setupCase5Constraints() {
        let imageView0 = imageViews[0]
        let imageView1 = imageViews[1]
        let imageView2 = imageViews[2]
        let imageView3 = imageViews[3]
        let imageView4 = imageViews[4]
        let smallSize = Layout.smallUnitSize
        let unitSize = Layout.unitSize
        let totalHeight = smallSize + Layout.spacing + unitSize

        case5Constraints = [
            imageView0.topAnchor.constraint(equalTo: topAnchor),
            imageView0.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView0.widthAnchor.constraint(equalToConstant: smallSize),
            imageView0.heightAnchor.constraint(equalToConstant: smallSize),

            imageView1.topAnchor.constraint(equalTo: topAnchor),
            imageView1.leadingAnchor.constraint(equalTo: imageView0.trailingAnchor, constant: Layout.spacing),
            imageView1.widthAnchor.constraint(equalToConstant: smallSize),
            imageView1.heightAnchor.constraint(equalToConstant: smallSize),

            imageView2.topAnchor.constraint(equalTo: topAnchor),
            imageView2.leadingAnchor.constraint(equalTo: imageView1.trailingAnchor, constant: Layout.spacing),
            imageView2.widthAnchor.constraint(equalToConstant: smallSize),
            imageView2.heightAnchor.constraint(equalToConstant: smallSize),
            imageView2.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView3.topAnchor.constraint(equalTo: imageView0.bottomAnchor, constant: Layout.spacing),
            imageView3.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView3.widthAnchor.constraint(equalToConstant: unitSize),
            imageView3.heightAnchor.constraint(equalToConstant: unitSize),
            imageView3.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView4.topAnchor.constraint(equalTo: imageView2.bottomAnchor, constant: Layout.spacing),
            imageView4.leadingAnchor.constraint(equalTo: imageView3.trailingAnchor, constant: Layout.spacing),
            imageView4.widthAnchor.constraint(equalToConstant: unitSize),
            imageView4.heightAnchor.constraint(equalToConstant: unitSize),
            imageView4.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView4.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(equalToConstant: Layout.maxContentWidth),
            heightAnchor.constraint(equalToConstant: totalHeight)
        ]
    }

    private func activateConstraints(for count: Int, aspectRatio: CGFloat?) {
        switch count {
        case 1:
            if let aspectRatio = aspectRatio {
                let calculatedHeight = Layout.maxContentWidth / aspectRatio
                let clampedHeight = min(max(calculatedHeight, Layout.singleImageMinHeight), Layout.singleImageMaxHeight)

                let heightConstraint = case1Constraints.first { $0.firstAttribute == .height }
                heightConstraint?.constant = clampedHeight
            }
            activeConstraints = case1Constraints
        case 2:
            activeConstraints = case2Constraints
        case 3:
            activeConstraints = case3Constraints
        case 4:
            activeConstraints = case4Constraints
        case 5:
            activeConstraints = case5Constraints
        default:
            break
        }

        NSLayoutConstraint.activate(activeConstraints)
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

    static func calculateHeight(for imageCount: Int, aspectRatio: CGFloat? = nil) -> CGFloat {
        switch imageCount {
        case 1:
            let ratio = aspectRatio ?? Layout.defaultAspectRatio
            let calculatedHeight = Layout.maxContentWidth / ratio
            return min(max(calculatedHeight, Layout.singleImageMinHeight), Layout.singleImageMaxHeight)
        case 2:
            return Layout.unitSize
        case 3, 4:
            return Layout.unitSize * 2 + Layout.spacing
        case 5:
            return Layout.smallUnitSize + Layout.spacing + Layout.unitSize
        default:
            return 0
        }
    }
}
