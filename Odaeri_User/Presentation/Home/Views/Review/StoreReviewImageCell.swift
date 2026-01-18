//
//  StoreReviewImageCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class StoreReviewImageCell: UICollectionViewCell {
    static let reuseIdentifier = "StoreReviewImageCell"

    private var currentUrl: String?

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.backgroundColor = AppColor.gray15
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(url: String) {
        if currentUrl == url {
            return
        }
        currentUrl = url
        imageView.setImage(url: url)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentUrl = nil
        imageView.image = nil
    }
}
