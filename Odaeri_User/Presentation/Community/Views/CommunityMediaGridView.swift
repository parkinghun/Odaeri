//
//  CommunityMediaGridView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit

final class CommunityMediaGridView: UIView {
    var onVideoSelected: ((URL) -> Void)?

    var likeTapPublisher: AnyPublisher<LikeButton.TapEvent, Never> {
        likeButton.tapPublisher.eraseToAnyPublisher()
    }

    private let leftItemView = CommunityMediaItemView()
    private let rightTopItemView = CommunityMediaItemView()
    private let rightBottomItemView = CommunityMediaItemView()

    private let likeButton = LikeButton()

    private lazy var rightStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [rightTopItemView, rightBottomItemView])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xSmall
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [leftItemView, rightStackView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.distribution = .fill
        return stackView
    }()

    private var rightWidthConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupInteractions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(horizontalStackView)
        addSubview(likeButton)

        horizontalStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        leftItemView.snp.makeConstraints {
            $0.height.equalTo(leftItemView.snp.width)
        }

        rightStackView.snp.makeConstraints {
            $0.height.equalTo(leftItemView.snp.height)
        }

        likeButton.snp.makeConstraints {
            $0.leading.equalTo(leftItemView.snp.leading).offset(AppSpacing.medium)
            $0.top.equalTo(leftItemView.snp.top).offset(AppSpacing.medium)
            $0.size.equalTo(24)
        }
    }

    private func setupInteractions() {
        leftItemView.onTap = { [weak self] item in
            self?.handleMediaTap(item)
        }
        rightTopItemView.onTap = { [weak self] item in
            self?.handleMediaTap(item)
        }
        rightBottomItemView.onTap = { [weak self] item in
            self?.handleMediaTap(item)
        }
    }

    func configure(items: [CommunityMediaItemViewModel], postId: String, isLiked: Bool) {
        leftItemView.reset()
        rightTopItemView.reset()
        rightBottomItemView.reset()

        likeButton.isHidden = items.isEmpty
        likeButton.configure(storeId: postId, isPicked: isLiked)

        updateLayout(for: items.count)

        guard let first = items.first else { return }
        leftItemView.configure(item: first, overlayText: nil)

        if items.count >= 2 {
            rightTopItemView.configure(item: items[1], overlayText: nil)
        }

        if items.count >= 3 {
            let overflowText = items.count > 3 ? "+\(items.count - 3)" : nil
            rightBottomItemView.configure(item: items[2], overlayText: overflowText)
        }
    }

    func reset() {
        leftItemView.reset()
        rightTopItemView.reset()
        rightBottomItemView.reset()
        likeButton.isHidden = true
    }

    private func updateLayout(for count: Int) {
        rightWidthConstraint?.deactivate()
        rightWidthConstraint = nil

        rightStackView.isHidden = count <= 1
        rightBottomItemView.isHidden = count <= 2

        if count == 2 {
            horizontalStackView.distribution = .fill
            rightStackView.distribution = .fill
            rightWidthConstraint = rightStackView.snp.prepareConstraints {
                $0.width.equalTo(leftItemView.snp.width)
            }.first
            rightWidthConstraint?.activate()
        } else if count >= 3 {
            horizontalStackView.distribution = .fill
            rightStackView.distribution = .fillEqually
            rightWidthConstraint = rightStackView.snp.prepareConstraints {
                $0.width.equalTo(leftItemView.snp.width)
                    .multipliedBy(0.5)
                    .offset(-AppSpacing.xSmall / 2)
            }.first
            rightWidthConstraint?.activate()
        } else {
            horizontalStackView.distribution = .fill
        }
    }

    private func handleMediaTap(_ item: CommunityMediaItemViewModel) {
        guard item.type == .video, let url = URL(string: item.url) else { return }
        onVideoSelected?(url)
    }
}
