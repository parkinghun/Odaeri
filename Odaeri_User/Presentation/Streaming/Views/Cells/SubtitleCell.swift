//
//  SubtitleCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import SnapKit

final class SubtitleCell: UITableViewCell {
    static let reuseIdentifier = "SubtitleCell"

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3
        label.textColor = AppColor.gray75
        label.textAlignment = .left
        return label
    }()

    private let subtitleTextLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray100
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        subtitleTextLabel.text = nil
        contentView.backgroundColor = AppColor.gray0
        timeLabel.textColor = AppColor.gray75
        subtitleTextLabel.textColor = AppColor.gray100
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppColor.gray0

        contentView.addSubview(timeLabel)
        contentView.addSubview(subtitleTextLabel)

        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(50)
        }

        subtitleTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(with subtitle: SubtitleItem, isHighlighted: Bool) {
        let minutes = Int(subtitle.startTime) / 60
        let seconds = Int(subtitle.startTime) % 60
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        subtitleTextLabel.text = subtitle.text

        if isHighlighted {
            contentView.backgroundColor = AppColor.brightSprout2
            timeLabel.textColor = AppColor.blackSprout
            subtitleTextLabel.textColor = AppColor.blackSprout
        } else {
            contentView.backgroundColor = AppColor.gray0
            timeLabel.textColor = AppColor.gray75
            subtitleTextLabel.textColor = AppColor.gray100
        }
    }
}
