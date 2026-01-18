//
//  StoreReviewRatingRowView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class StoreReviewRatingRowView: UIView {
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray75
        return label
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.trackTintColor = AppColor.gray30
        view.progressTintColor = AppColor.brightForsythia
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .right
        return label
    }()

    private lazy var contentStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [ratingLabel, progressView, countLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        ratingLabel.snp.makeConstraints {
            $0.width.equalTo(26)
        }

        countLabel.snp.makeConstraints {
            $0.width.equalTo(32)
        }

        progressView.snp.makeConstraints {
            $0.height.equalTo(8)
        }
    }

    func configure(rating: Int, count: Int, ratio: Float) {
        ratingLabel.text = "\(rating)점"
        countLabel.text = "\(count)"
        progressView.setProgress(ratio, animated: true)
    }
}
