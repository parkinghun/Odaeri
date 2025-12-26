//
//  TopSearchView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import SnapKit

final class TrendingSearchTickerView: BaseView {
    private var rank: String
    private var searchText: String
    
    var onSearchTapped: ((String) -> Void)?
    
    private let iconImageView: UIImageView = {
        let image = AppImage.default?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = AppColor.deepSprout
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "인기검색어"
        label.font = AppFont.caption
        label.textColor = AppColor.deepSprout
        return label
    }()
    
    private lazy var searchKeywordButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.blackSprout
        button.titleLabel?.font = AppFont.caption
        button.contentHorizontalAlignment = .leading
        
        let title = "\(rank) \(searchText)"
        button.setTitle(title, for: .normal)
        
        button.addTarget(self, action: #selector(keywordTappped), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            iconImageView,
            titleLabel,
            searchKeywordButton
        ])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    init(
        rank: String = "1",
        searchText: String = "스타벅스"
    ) {
        self.rank = rank
        self.searchText = searchText
        super.init(frame: .zero)
    }
    
    override func setupView() {
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(16)
        }
    }
    
    func updateSearch(rank: String, text: String) {
        self.rank = rank
        self.searchText = text
        
        UIView.transition(with: searchKeywordButton, duration: 0.3, options: .transitionCrossDissolve) {
            self.searchKeywordButton.setTitle("\(rank) \(text)", for: .normal)
        }
    }
    
    @objc private func keywordTappped() {
        onSearchTapped?(searchText)
    }
}
