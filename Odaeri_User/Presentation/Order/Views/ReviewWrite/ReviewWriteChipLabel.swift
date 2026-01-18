//
//  ReviewWriteChipLabel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit

final class ReviewWriteChipLabel: UILabel {
    private let contentInset = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = AppFont.caption1
        textColor = AppColor.blackSprout
        backgroundColor = AppColor.brightSprout
        layer.cornerRadius = 10
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }
}

