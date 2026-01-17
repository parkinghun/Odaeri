//
//  CommunityMediaItemView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class CommunityMediaItemView: UIView {
    var onTap: ((CommunityMediaItemViewModel) -> Void)?

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let playIconView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "play.fill"))
        view.tintColor = AppColor.gray0
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray100.withAlphaComponent(0.6)
        view.isHidden = true
        return view
    }()

    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray0
        return label
    }()

    private let tapButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()

    private var currentItem: CommunityMediaItemViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(imageView)
        addSubview(playIconView)
        addSubview(overlayView)
        overlayView.addSubview(overlayLabel)
        addSubview(tapButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        playIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(28)
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        tapButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        tapButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        guard let item = currentItem else { return }
        onTap?(item)
    }

    func configure(item: CommunityMediaItemViewModel, overlayText: String?) {
        currentItem = item
        overlayLabel.text = overlayText
        overlayView.isHidden = overlayText == nil

        playIconView.isHidden = item.type != .video

        imageView.resetImage()

        if item.type == .image {
            imageView.setImage(url: item.url)
        } else if item.type == .video {
            if let thumbnailUrl = item.thumbnailUrl {
                imageView.setImage(url: thumbnailUrl)
            } else {
                imageView.setVideoThumbnail(url: item.url)
            }
        }
    }

    func reset() {
        currentItem = nil
        imageView.resetImage()
        overlayView.isHidden = true
        playIconView.isHidden = true
    }
}
