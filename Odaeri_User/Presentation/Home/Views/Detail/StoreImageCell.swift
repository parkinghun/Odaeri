//
//  StoreImageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit
import SnapKit

final class StoreImageCell: BaseCollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    override func setupUI() {
        super.setupUI()
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.resetImage()
    }

    func configure(with urlString: String?) {
        imageView.setImage(url: urlString)
    }
}

