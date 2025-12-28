//
//  Divider.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import SnapKit

final class Divider: BaseView {
    private let height: CGFloat
    private let color: UIColor

    init(
        height: CGFloat = 1,
        color: UIColor = AppColor.gray30
    ) {
        self.height = height
        self.color = color
        super.init(frame: .zero)
    }

    override func setupView() {
        backgroundColor = color
        snp.makeConstraints { $0.height.equalTo(height) }
    }
}
