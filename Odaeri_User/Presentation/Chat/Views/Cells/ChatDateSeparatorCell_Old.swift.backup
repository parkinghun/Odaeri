//
//  ChatDateSeparatorCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class ChatDateSeparatorCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ChatDateSeparatorCell.self)

    private let label: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = AppColor.gray0
        contentView.addSubview(label)

        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(AppSpacing.small)
            $0.centerX.equalToSuperview()
        }
    }

    func configure(text: String) {
        label.text = text
    }
}
