//
//  ShareTargetEmptyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import SnapKit

final class ShareTargetEmptyView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
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

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func setupUI() {
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.screenMargin)
        }
    }
}
