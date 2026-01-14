//
//  ChatInputAttachmentItemView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/13/26.
//

import UIKit
import SnapKit

final class ChatInputAttachmentItemView: UIView {
    private let imageView = UIImageView()
    private let removeButton = UIButton(type: .system)
    private let playIconView = UIImageView()
    private let fileNameLabel = UILabel()

    var onRemove: (() -> Void)?
    var onTap: (() -> Void)?

    private enum Layout {
        static let removeButtonSize: CGFloat = 20
        static let playIconSize: CGFloat = 24
        static let cornerRadius: CGFloat = 8
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ChatInputAttachmentItem) {
        imageView.image = item.displayImage
        playIconView.isHidden = !item.isVideo

        if let displayFileName = item.displayFileName {
            fileNameLabel.text = displayFileName
            fileNameLabel.isHidden = false
        } else {
            fileNameLabel.isHidden = true
        }
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.gray30

        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = AppColor.gray0
        removeButton.backgroundColor = AppColor.gray90.withAlphaComponent(0.8)
        removeButton.layer.cornerRadius = Layout.removeButtonSize / 2
        removeButton.clipsToBounds = true

        playIconView.image = UIImage(systemName: "play.circle.fill")
        playIconView.tintColor = AppColor.gray0
        playIconView.contentMode = .scaleAspectFit
        playIconView.isHidden = true
        playIconView.layer.shadowColor = UIColor.black.cgColor
        playIconView.layer.shadowOpacity = 0.3
        playIconView.layer.shadowOffset = .zero
        playIconView.layer.shadowRadius = 4

        fileNameLabel.font = AppFont.caption2
        fileNameLabel.textColor = AppColor.gray75
        fileNameLabel.textAlignment = .center
        fileNameLabel.numberOfLines = 2
        fileNameLabel.isHidden = true

        addSubview(imageView)
        addSubview(playIconView)
        addSubview(fileNameLabel)
        addSubview(removeButton)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        removeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(4)
            $0.size.equalTo(Layout.removeButtonSize)
        }

        playIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(Layout.playIconSize)
        }

        fileNameLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.bottom.equalToSuperview().inset(4)
        }
    }

    private func setupActions() {
        removeButton.addTarget(self, action: #selector(handleRemove), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleRemove() {
        onRemove?()
    }

    @objc private func handleTap() {
        onTap?()
    }
}
