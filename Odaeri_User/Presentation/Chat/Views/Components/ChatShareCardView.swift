//
//  ChatShareCardView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import SnapKit

final class ChatShareCardView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray30.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.gray15
        return imageView
    }()

    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2
        label.textColor = AppColor.gray60
        label.text = "공유"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray90
        label.numberOfLines = 2
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [tagLabel, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.alignment = .leading
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(payload: ShareCardPayload) {
        titleLabel.text = payload.title
        thumbnailImageView.setImage(
            url: payload.thumbnailUrl,
            placeholder: AppImage.default,
            animated: false,
            downsample: true
        )
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(textStackView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }

        textStackView.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
}
