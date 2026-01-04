//
//  MenuCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit
import SnapKit

final class MenuCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .leading
        return stackView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3
        label.textColor = AppColor.gray60
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let menuImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let soldOutView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray90.withAlphaComponent(0.6)
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    private let soldOutLabel: UILabel = {
        let label = UILabel()
        label.text = "품절"
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray0
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)

        containerView.addSubview(tagsStackView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(menuImageView)

        menuImageView.addSubview(soldOutView)
        soldOutView.addSubview(soldOutLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        menuImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppSpacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(80)
        }

        tagsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.medium)
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(tagsStackView.snp.bottom).offset(AppSpacing.xSmall)
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppSpacing.tiny)
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(AppSpacing.small)
            make.leading.equalToSuperview().offset(AppSpacing.medium)
            make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
            make.bottom.equalToSuperview().inset(AppSpacing.medium)
        }

        soldOutView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        soldOutLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        menuImageView.resetImage()
        soldOutView.isHidden = true
        setSelected(false)
    }

    func setSelected(_ selected: Bool) {
        if selected {
            containerView.backgroundColor = AppColor.brightSprout
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = AppColor.deepSprout.cgColor
        } else {
            containerView.backgroundColor = AppColor.gray0
            containerView.layer.borderWidth = 0
        }
    }

    func configure(with menu: MenuEntity) {
        nameLabel.text = menu.name
        descriptionLabel.text = menu.description
        priceLabel.text = menu.formattedPrice
        menuImageView.setImage(url: menu.menuImageUrl)
        soldOutView.isHidden = !menu.isSoldOut

        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for tag in menu.tags {
            let tagLabel = UILabel()
            tagLabel.text = "#\(tag)"
            tagLabel.font = AppFont.caption1
            tagLabel.textColor = AppColor.deepSprout
            tagsStackView.addArrangedSubview(tagLabel)
        }

        if menu.tags.isEmpty {
            tagsStackView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(0)
            }
            nameLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(AppSpacing.medium)
                make.leading.equalToSuperview().offset(AppSpacing.medium)
                make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
            }
        } else {
            tagsStackView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(AppSpacing.medium)
            }
            nameLabel.snp.remakeConstraints { make in
                make.top.equalTo(tagsStackView.snp.bottom).offset(AppSpacing.xSmall)
                make.leading.equalToSuperview().offset(AppSpacing.medium)
                make.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-AppSpacing.small)
            }
        }
    }
}
