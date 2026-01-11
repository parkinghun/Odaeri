//
//  ChatFileView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import UIKit
import SnapKit

final class ChatFileView: UIView {
    var onFileTapped: (() -> Void)?

    private let containerStackView = UIStackView()
    private let fileIconImageView = UIImageView()
    private let textStackView = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileSizeLabel = UILabel()

    private enum Layout {
        static let viewCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 0.5
        static let height: CGFloat = 60
        static let iconSize: CGFloat = 40
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 10
        static let stackSpacing: CGFloat = 12
        static let textStackSpacing: CGFloat = 2
        static let minTextWidth: CGFloat = 100
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with fileInfo: ChatMessageContent.FileInfo) {
        fileNameLabel.text = fileInfo.fileName

        if let fileSize = fileInfo.fileSize {
            fileSizeLabel.text = formatFileSize(fileSize)
            fileSizeLabel.isHidden = false
        } else {
            fileSizeLabel.isHidden = true
        }
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = Layout.viewCornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = AppColor.gray30.cgColor
        backgroundColor = AppColor.gray15

        containerStackView.axis = .horizontal
        containerStackView.spacing = Layout.stackSpacing
        containerStackView.alignment = .center
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.layoutMargins = UIEdgeInsets(
            top: Layout.verticalPadding,
            left: Layout.horizontalPadding,
            bottom: Layout.verticalPadding,
            right: Layout.horizontalPadding
        )

        fileIconImageView.image = UIImage(systemName: "doc.fill")
        fileIconImageView.tintColor = AppColor.blackSprout
        fileIconImageView.contentMode = .scaleAspectFit

        textStackView.axis = .vertical
        textStackView.spacing = Layout.textStackSpacing
        textStackView.alignment = .leading

        fileNameLabel.font = AppFont.body3
        fileNameLabel.textColor = AppColor.gray90
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        fileSizeLabel.font = AppFont.caption2
        fileSizeLabel.textColor = AppColor.gray60

        addSubview(containerStackView)

        containerStackView.addArrangedSubview(fileIconImageView)
        containerStackView.addArrangedSubview(textStackView)

        textStackView.addArrangedSubview(fileNameLabel)
        textStackView.addArrangedSubview(fileSizeLabel)

        containerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }

        fileIconImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.iconSize)
        }

        textStackView.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(Layout.minTextWidth)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        onFileTapped?()
    }

    private func formatFileSize(_ sizeString: String) -> String {
        if let bytes = Int64(sizeString) {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
        return sizeString
    }

    static func calculateHeight() -> CGFloat {
        return Layout.height
    }
}
