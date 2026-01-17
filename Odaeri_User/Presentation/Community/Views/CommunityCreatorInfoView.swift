//
//  CommunityCreatorInfoView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class CommunityCreatorInfoView: UIView {
    var onTap: (() -> Void)?

    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 16
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.gray90
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2Medium
        label.textColor = AppColor.gray60
        return label
    }()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(profileImageView)
        addSubview(infoStackView)

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(32)
            $0.leading.top.bottom.equalToSuperview()
        }

        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(AppSpacing.small)
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(profileImageView)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }

    func configure(name: String, createdAtText: String, profileImageUrl: String?) {
        nameLabel.text = name
        timeLabel.text = createdAtText
        profileImageView.setImage(url: profileImageUrl)
    }
}
