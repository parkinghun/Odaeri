//
//  ReviewWriteHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class ReviewWriteHeaderView: UIView {
    private enum Layout {
        static let imageSize: CGFloat = 52
    }

    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let menuChipLabel = ReviewWriteChipLabel()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeNameLabel, menuChipLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        stackView.alignment = .leading
        return stackView
    }()

    private lazy var rootStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeImageView, textStackView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.medium
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
        addSubview(rootStackView)
        rootStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        storeImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.imageSize)
        }
    }

    func configure(with header: ReviewWriteHeader) {
        storeNameLabel.text = header.storeName
        menuChipLabel.text = header.menuSummary
        storeImageView.setImage(url: header.storeImageUrl)
    }
}
