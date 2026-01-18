//
//  StoreReviewPhotoPreviewCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/19/26.
//

import UIKit
import SnapKit

final class StoreReviewPhotoPreviewCell: UITableViewCell {
    static let reuseIdentifier = "StoreReviewPhotoPreviewCell"

    private enum Layout {
        static let previewSize: CGFloat = 88
        static let actionWidth: CGFloat = 64
        static let maxPreviewCount = 4
    }

    private var previewImageViews: [UIImageView] = []
    private var currentImageUrls: [String] = []

    private let previewStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xSmall
        stackView.alignment = .center
        return stackView
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(AppImage.cheveronRight, for: .normal)
        button.tintColor = AppColor.gray75
        return button
    }()

    private let actionTapButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.text = "사진 리뷰가 없습니다"
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var actionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [actionButton, countLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        stackView.alignment = .center
        return stackView
    }()

    private let actionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 10
        return view
    }()

    private let spacerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [previewStackView, spacerView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.medium
        stackView.alignment = .center
        return stackView
    }()

    var onGalleryTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(contentStackView)
        contentView.addSubview(emptyLabel)

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.medium)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.bottom.equalToSuperview().offset(-AppSpacing.medium)
        }

        emptyLabel.snp.makeConstraints {
            $0.edges.equalTo(contentStackView)
        }

        // 미리 4개의 이미지뷰 생성
        for _ in 0..<Layout.maxPreviewCount {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 12
            imageView.clipsToBounds = true
            imageView.backgroundColor = AppColor.gray15
            imageView.isHidden = true
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(Layout.previewSize)
            }
            previewImageViews.append(imageView)
            previewStackView.addArrangedSubview(imageView)
        }

        previewStackView.addArrangedSubview(actionContainer)

        actionContainer.snp.makeConstraints {
            $0.width.equalTo(Layout.actionWidth)
            $0.height.equalTo(Layout.previewSize)
        }

        actionContainer.addSubview(actionStackView)
        actionContainer.addSubview(actionTapButton)
        actionStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        actionTapButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        previewStackView.setContentHuggingPriority(.required, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        actionButton.addTarget(self, action: #selector(handleGalleryTap), for: .touchUpInside)
        actionTapButton.addTarget(self, action: #selector(handleGalleryTap), for: .touchUpInside)
    }

    func configure(imageUrls: [String]) {
        // 이전과 동일한 URL이면 업데이트하지 않음 (깜빡임 방지)
        if currentImageUrls == imageUrls {
            return
        }
        currentImageUrls = imageUrls

        if imageUrls.isEmpty {
            contentStackView.isHidden = true
            emptyLabel.isHidden = false
            countLabel.text = "0장"
            actionButton.isHidden = true
            previewImageViews.forEach { $0.isHidden = true }
            return
        }

        contentStackView.isHidden = false
        emptyLabel.isHidden = true
        countLabel.text = "\(imageUrls.count)장"
        actionButton.isHidden = false

        let previewUrls = Array(imageUrls.prefix(Layout.maxPreviewCount))

        // 필요한 개수만큼 이미지뷰 표시하고 URL 설정
        for (index, imageView) in previewImageViews.enumerated() {
            if index < previewUrls.count {
                imageView.isHidden = false
                imageView.setImage(url: previewUrls[index])
            } else {
                imageView.isHidden = true
                imageView.image = nil
            }
        }
    }

    @objc private func handleGalleryTap() {
        onGalleryTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentImageUrls = []
        previewImageViews.forEach {
            $0.isHidden = true
        }
    }
}
