//
//  StoreReviewSummaryView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class StoreReviewSummaryView: UIView {
    private let averageTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.text = "평균 별점"
        label.textAlignment = .center
        return label
    }()

    private let averageValueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.brandTitle2
        label.textColor = AppColor.gray90
        label.textAlignment = .center
        return label
    }()

    private let totalCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    private lazy var averageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [averageTitleLabel, averageValueLabel, totalCountLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        stackView.alignment = .center
        return stackView
    }()

    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        return stackView
    }()

    private var ratingRows: [StoreReviewRatingRowView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0

        addSubview(averageStackView)
        addSubview(ratingStackView)

        averageStackView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.equalTo(96)
        }

        ratingStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(averageStackView.snp.trailing).offset(AppSpacing.large)
            $0.trailing.bottom.equalToSuperview()
        }

        ratingRows = (1...5).reversed().map { rating in
            let row = StoreReviewRatingRowView()
            row.configure(rating: rating, count: 0, ratio: 0)
            ratingStackView.addArrangedSubview(row)
            return row
        }
    }

    func configure(with summary: StoreReviewSummaryViewModel) {
        averageValueLabel.text = summary.averageRatingText
        totalCountLabel.text = summary.totalCountText

        for (index, row) in ratingRows.enumerated() where index < summary.ratingRows.count {
            let model = summary.ratingRows[index]
            row.configure(rating: model.rating, count: model.count, ratio: model.ratio)
        }
    }
}
