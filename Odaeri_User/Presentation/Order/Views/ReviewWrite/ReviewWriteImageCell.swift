//
//  ReviewWriteImageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class ReviewWriteImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ReviewWriteImageCell"

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColor.gray0
        return button
    }()

    var onDeleteTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(removeButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        removeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
            $0.size.equalTo(22)
        }

        removeButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    }

    func configure(image: UIImage) {
        imageView.image = image
    }

    func configure(url: String) {
        imageView.setImage(url: url)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    @objc private func handleDelete() {
        onDeleteTapped?()
    }
}
