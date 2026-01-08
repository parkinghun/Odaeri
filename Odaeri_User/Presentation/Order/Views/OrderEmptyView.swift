//
//  OrderEmptyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class OrderEmptyView: UIView {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.sesac.withRenderingMode(.alwaysTemplate)
        view.tintColor = AppColor.brightSprout
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문 내역이 없습니다."
        label.font = AppFont.brandTitle1
        label.textColor = AppColor.brightSprout
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "건강한 픽업 생활의 시작, 오대리"
        label.font = AppFont.brandTitle1
        label.textColor = AppColor.brightSprout
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
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

    private func setupUI() {
        addSubview(stackView)

        imageView.snp.makeConstraints {
            $0.size.equalTo(62)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
