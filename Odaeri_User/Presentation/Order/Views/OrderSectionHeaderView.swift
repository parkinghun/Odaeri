//
//  OrderSectionHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class OrderSectionHeaderView: UICollectionReusableView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(topDivider)
        addSubview(titleLabel)
        topDivider.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(1)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.top.bottom.equalToSuperview()
        }
    }

    func configure(title: String, textColor: UIColor) {
        titleLabel.text = title
        titleLabel.textColor = textColor
    }
}
