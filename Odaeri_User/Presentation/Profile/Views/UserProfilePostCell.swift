//
//  UserProfilePostCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class UserProfilePostCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: UserProfilePostCell.self)

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.resetImage(placeholder: AppImage.default)
    }

    func configure(imageUrl: String?) {
        imageView.resetImage(placeholder: AppImage.default)
        imageView.setImage(url: imageUrl, placeholder: AppImage.default)
    }

    private func setupUI() {
        contentView.addSubview(imageView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.gray15

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
