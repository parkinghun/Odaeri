//
//  ReviewWriteImageAddCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class ReviewWriteImageAddCell: UICollectionViewCell {
    static let reuseIdentifier = "ReviewWriteImageAddCell"

    private let iconView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "plus"))
        view.tintColor = AppColor.gray60
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppColor.gray30.cgColor

        contentView.addSubview(iconView)
        contentView.addSubview(countLabel)

        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(22)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
    }

    func configure(currentCount: Int, maxCount: Int) {
        countLabel.text = "\(currentCount)/\(maxCount)"
    }
}

