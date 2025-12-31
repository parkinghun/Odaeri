//
//  BaseCollectionViewCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/31/25.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        // Override point for subclasses
    }
}
