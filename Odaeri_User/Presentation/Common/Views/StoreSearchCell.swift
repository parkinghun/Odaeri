//
//  StoreSearchCell.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import UIKit
import SnapKit

final class StoreSearchCell: UITableViewCell {
    static let identifier = "StoreSearchCell"

    private let storeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.gray30
        return imageView
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1
        label.textColor = AppColor.gray100
        label.numberOfLines = 1
        return label
    }()

    private let distanceBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 10
        view.isHidden = true
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()

    private let distanceBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray90
        label.numberOfLines = 1
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3
        label.textColor = AppColor.gray60
        label.numberOfLines = 1
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray75
        label.numberOfLines = 1
        return label
    }()

    private let visitDateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        storeImageView.resetImage()
        distanceBadgeView.isHidden = true
        distanceBadgeLabel.text = nil
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0
        selectionStyle = .none

        contentView.addSubview(storeImageView)
        contentView.addSubview(storeNameLabel)
        contentView.addSubview(distanceBadgeView)
        distanceBadgeView.addSubview(distanceBadgeLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(visitDateLabel)
    }

    private func setupConstraints() {
        storeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        storeNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(storeImageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(distanceBadgeView.snp.leading).offset(-8)
        }

        distanceBadgeView.snp.makeConstraints {
            $0.centerY.equalTo(storeNameLabel)
            $0.leading.equalTo(storeNameLabel.snp.trailing).offset(8)
            $0.height.equalTo(20)
        }

        distanceBadgeLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }

        categoryLabel.snp.makeConstraints {
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(storeImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(4)
            $0.leading.equalTo(storeImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(16)
        }

        visitDateLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(4)
            $0.leading.equalTo(storeImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    func configure(with store: StoreEntity) {
        storeNameLabel.text = store.name
        categoryLabel.text = store.category
        addressLabel.text = store.address
        addressLabel.isHidden = false
        visitDateLabel.isHidden = true
        distanceBadgeView.isHidden = true

        storeImageView.layer.cornerRadius = 8
        storeImageView.setImage(url: store.storeImageUrls.first)
    }

    func configure(with item: StoreSearchListItem) {
        storeNameLabel.text = item.store.name
        categoryLabel.text = item.store.category
        addressLabel.text = item.store.address
        addressLabel.isHidden = false
        visitDateLabel.isHidden = true

        if let distanceText = item.distanceText {
            distanceBadgeLabel.text = distanceText
            distanceBadgeView.isHidden = false
        } else {
            distanceBadgeView.isHidden = true
        }

        storeImageView.layer.cornerRadius = 8
        storeImageView.setImage(url: item.store.storeImageUrls.first)
    }

    func configure(with item: RecentStoreItem) {
        storeNameLabel.text = item.store.name
        categoryLabel.text = item.store.category
        addressLabel.isHidden = true
        visitDateLabel.isHidden = false
        distanceBadgeView.isHidden = true

        if let paidAt = item.paidAt {
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let paidYear = calendar.component(.year, from: paidAt)

            let dateString: String
            if currentYear == paidYear {
                dateString = DateFormatter.monthDay.string(from: paidAt)
            } else {
                dateString = DateFormatter.dotDate.string(from: paidAt)
            }
            visitDateLabel.text = "최근 구매한 날짜: \(dateString)"
        } else {
            visitDateLabel.text = ""
        }

        storeImageView.layer.cornerRadius = 8
        storeImageView.setImage(url: item.store.storeImageUrls.first)
    }
}
