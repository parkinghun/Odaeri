//
//  TopSearchView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import SnapKit

final class TrendingSearchTickerView: BaseView {
    private var keywords: [String] = []
    private var currentIndex: Int = 0
    private var timer: Timer?

    var onSearchTapped: ((String) -> Void)?

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: AppImage.default)
        imageView.tintColor = AppColor.deepSprout
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "인기검색어"
        label.font = AppFont.caption
        label.textColor = AppColor.deepSprout
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var searchKeywordButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.blackSprout
        button.titleLabel?.font = AppFont.caption
        button.contentHorizontalAlignment = .leading
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    deinit {
        stopTimer()
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

    func configure(with keywords: [String]) {
        self.keywords = keywords
        self.currentIndex = 0

        stopTimer()

        guard !keywords.isEmpty else { return }

        updateKeywordDisplay()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.showNextKeyword()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func showNextKeyword() {
        guard !keywords.isEmpty else { return }

        currentIndex = (currentIndex + 1) % keywords.count
        updateKeywordDisplay()
    }

    private func updateKeywordDisplay() {
        guard !keywords.isEmpty else { return }

        let rank = currentIndex + 1
        let keyword = keywords[currentIndex]
        let title = "\(rank) \(keyword)"

        UIView.transition(with: searchKeywordButton, duration: 0.3, options: .transitionCrossDissolve) {
            self.searchKeywordButton.setTitle(title, for: .normal)
        }
    }

    @objc private func keywordTappped() {
        guard !keywords.isEmpty else { return }
        onSearchTapped?(keywords[currentIndex])
    }
}
