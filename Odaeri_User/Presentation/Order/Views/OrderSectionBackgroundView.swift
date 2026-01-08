//
//  OrderSectionBackgroundView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit

final class OrderSectionBackgroundCurrentView: UICollectionReusableView {
    static let kind = "OrderSectionBackgroundCurrentView"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.gray15
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OrderSectionBackgroundPastView: UICollectionReusableView {
    static let kind = "OrderSectionBackgroundPastView"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.gray0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
