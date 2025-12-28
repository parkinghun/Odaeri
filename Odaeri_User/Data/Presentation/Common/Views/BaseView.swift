//
//  BaseView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        // Override in subclasses
    }

    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
}
