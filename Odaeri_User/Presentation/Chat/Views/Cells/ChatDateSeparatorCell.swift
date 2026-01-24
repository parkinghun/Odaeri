//
//  ChatDateSeparatorCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit

final class ChatDateSeparatorCell: BaseCollectionViewCell {
    static let reuseIdentifier = String(describing: ChatDateSeparatorCell.self)

    private let label = UILabel()
    private var currentLayoutData: ChatDateSeparatorCellLayoutData?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()

        contentView.backgroundColor = AppColor.gray0

        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .center

        contentView.addSubview(label)
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attrs = layoutAttributes as? ChatCollectionViewLayoutAttributes,
              case .dateSeparator(let layoutData) = attrs.cellLayoutData else {
            return
        }

        currentLayoutData = layoutData
        configure(with: layoutData)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let layoutData = currentLayoutData else { return }
        label.frame = layoutData.labelFrame
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        currentLayoutData = nil
    }

    private func configure(with layoutData: ChatDateSeparatorCellLayoutData) {
        label.text = layoutData.text
    }
}
