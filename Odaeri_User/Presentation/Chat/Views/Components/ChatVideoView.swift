//
//  ChatVideoView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import UIKit
import SnapKit

final class ChatVideoView: UIView {
    var onVideoTapped: (() -> Void)?

    private let thumbnailImageView = UIImageView()
    private let overlayView = UIView()
    private let centerStackView = UIStackView()
    private let playIconImageView = UIImageView()
    private let durationLabel = UILabel()

    private enum Layout {
        static let viewCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 0.5
        static let minHeight: CGFloat = 120
        static let maxHeight: CGFloat = 400
        static let maxContentWidth: CGFloat = UIScreen.main.bounds.width * 0.75
        static let playIconSize: CGFloat = 60
        static let overlayAlpha: CGFloat = 0.25
        static let stackSpacing: CGFloat = 8
        static let defaultAspectRatio: CGFloat = 16.0 / 9.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with url: String, duration: String? = nil, aspectRatio: CGFloat? = nil) {
        thumbnailImageView.setImage(
            url: url,
            placeholder: AppImage.default,
            animated: true,
            downsample: true
        )

        durationLabel.text = duration
        durationLabel.isHidden = duration == nil

        updateLayout(aspectRatio: aspectRatio)
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = Layout.viewCornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = AppColor.gray30.cgColor

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = AppColor.gray15

        overlayView.backgroundColor = AppColor.gray100
        overlayView.alpha = Layout.overlayAlpha

        centerStackView.axis = .vertical
        centerStackView.spacing = Layout.stackSpacing
        centerStackView.alignment = .center
        centerStackView.isUserInteractionEnabled = false

        playIconImageView.image = UIImage(systemName: "play.circle.fill")
        playIconImageView.tintColor = AppColor.gray0
        playIconImageView.contentMode = .scaleAspectFit
        playIconImageView.isUserInteractionEnabled = false
        playIconImageView.layer.shadowColor = UIColor.black.cgColor
        playIconImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        playIconImageView.layer.shadowOpacity = 0.3
        playIconImageView.layer.shadowRadius = 4

        durationLabel.font = AppFont.caption1
        durationLabel.textColor = AppColor.gray0
        durationLabel.textAlignment = .center
        durationLabel.isUserInteractionEnabled = false
        durationLabel.layer.shadowColor = UIColor.black.cgColor
        durationLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        durationLabel.layer.shadowOpacity = 0.5
        durationLabel.layer.shadowRadius = 2

        addSubview(thumbnailImageView)
        addSubview(overlayView)
        addSubview(centerStackView)

        centerStackView.addArrangedSubview(playIconImageView)
        centerStackView.addArrangedSubview(durationLabel)

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        centerStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.playIconSize)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    private func updateLayout(aspectRatio: CGFloat?) {
        let ratio = aspectRatio ?? Layout.defaultAspectRatio
        let calculatedHeight = Layout.maxContentWidth / ratio
        let boundedHeight = min(max(calculatedHeight, Layout.minHeight), Layout.maxHeight)

        thumbnailImageView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(Layout.maxContentWidth)
            $0.height.equalTo(boundedHeight).priority(.high)
        }
    }

    @objc private func handleTap() {
        onVideoTapped?()
    }

    static func calculateHeight(aspectRatio: CGFloat? = nil) -> CGFloat {
        let ratio = aspectRatio ?? Layout.defaultAspectRatio
        let calculatedHeight = Layout.maxContentWidth / ratio
        return min(max(calculatedHeight, Layout.minHeight), Layout.maxHeight)
    }
}
