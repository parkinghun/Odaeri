//
//  StreamingListCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import UIKit
import SnapKit

final class StreamingListCell: UITableViewCell {
    static let reuseIdentifier = String(describing: StreamingListCell.self)

    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray90
        return view
    }()

    private let durationContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColor.gray100
        label.numberOfLines = 2
        return label
    }()

    private let metaInfoLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = AppColor.gray0

        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.addSubview(durationContainerView)
        durationContainerView.addSubview(durationLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(metaInfoLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(9.0 / 16.0)
        }

        durationContainerView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
        }

        durationLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(6)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        metaInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.resetImage()
        titleLabel.text = nil
        metaInfoLabel.text = nil
        durationLabel.text = nil
    }

    func configure(with display: StreamingVideoDisplay, durationText: String?) {
        thumbnailImageView.setImage(
            url: display.thumbnailUrl,
            placeholder: nil,
            animated: false
        )

        titleLabel.text = display.title

        let metaInfo = "조회수 \(display.viewCountText) • \(display.createdAtText)"
        metaInfoLabel.text = metaInfo

        if let durationText = durationText {
            durationLabel.text = durationText
            durationContainerView.isHidden = false
        } else {
            durationContainerView.isHidden = true
        }
    }
}
