//
//  IconLabelView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit
import SnapKit

final class IconLabelView: UIView {
    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let iconSize: CGFloat
    private let spacing: CGFloat

    init(
        icon: UIImage?,
        iconSize: CGFloat = 20,
        iconColor: UIColor? = nil,
        spacing: CGFloat = AppSpacing.tiny,
        font: UIFont = AppFont.body2,
        textColor: UIColor = AppColor.gray60
    ) {
        self.iconSize = iconSize
        self.spacing = spacing

        super.init(frame: .zero)

        iconImageView.image = icon
        iconImageView.tintColor = iconColor
        textLabel.font = font
        textLabel.textColor = textColor

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(textLabel)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(iconSize)
        }

        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func updateText(_ text: String) {
        textLabel.text = text
    }
}
