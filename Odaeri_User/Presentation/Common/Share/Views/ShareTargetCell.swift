//
//  ShareTargetCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import SnapKit

final class ShareTargetCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: ShareTargetCell.self)

    private enum Layout {
        static let imageSize: CGFloat = 56
        static let badgeSize: CGFloat = 18
        static let badgeImageSize: CGFloat = 12
        static let verticalSpacing: CGFloat = 8
        static let badgeOffset: CGFloat = (imageSize / 2) * 0.7071
    }

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.gray15
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray90
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.borderColor = AppColor.gray30.cgColor
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let badgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = AppImage.check.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = AppColor.blackSprout
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, nameLabel])
        stackView.axis = .vertical
        stackView.spacing = Layout.verticalSpacing
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = Layout.imageSize / 2
        badgeView.layer.cornerRadius = Layout.badgeSize / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        badgeView.isHidden = true
    }

    func configure(with model: ShareTargetDisplayModel) {
        nameLabel.text = model.nick
        profileImageView.setImage(
            url: model.profileImage,
            placeholder: AppImage.person,
            animated: false,
            downsample: true
        )
        badgeView.isHidden = !model.isSelected
    }

    private func setupUI() {
        contentView.backgroundColor = AppColor.gray0
        contentView.addSubview(contentStackView)
        contentView.addSubview(badgeView)
        badgeView.addSubview(badgeImageView)

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        profileImageView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.imageSize)
        }

        badgeView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.badgeSize)
            make.centerX.equalTo(profileImageView).offset(Layout.badgeOffset)
            make.centerY.equalTo(profileImageView).offset(-Layout.badgeOffset)
        }

        badgeImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.badgeImageSize)
        }
    }
}
