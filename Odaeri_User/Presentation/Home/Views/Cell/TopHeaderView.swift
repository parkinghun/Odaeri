//
//  TopHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import UIKit
import SnapKit

final class TopHeaderView: UICollectionReusableView {
    private let searchBar = SearchBar()
    private let trendingSearchTickerView = TrendingSearchTickerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(searchBar)
        addSubview(trendingSearchTickerView)

        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
        }

        trendingSearchTickerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with keywords: [String]) {
        trendingSearchTickerView.configure(with: keywords)
    }
}
