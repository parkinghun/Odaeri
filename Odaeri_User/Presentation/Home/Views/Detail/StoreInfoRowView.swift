//
//  StoreInfoRowView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit
import SnapKit
import Combine

final class StoreInfoRowView: UIView {
    enum Info: String {
        case address = "가게주소"
        case time = "영업시간"
        case parking = "주차여부"

        var icon: UIImage {
            switch self {
            case .address: AppImage.distance
            case .time: AppImage.time
            case .parking: AppImage.parking
            }
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.numberOfLines = 0
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
        addSubview(titleLabel)
        addSubview(iconImageView)
        addSubview(infoLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(AppSpacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        infoLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(AppSpacing.xSmall)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func configure(info: Info, text: String) {
        titleLabel.text = info.rawValue
        iconImageView.image = info.icon
        iconImageView.tintColor = AppColor.deepSprout
        infoLabel.text = text
    }
}
