//
//  CommunityStoreInfoView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class CommunityStoreInfoView: UIView {
    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let divider = Divider(color: AppColor.deepSprout)
    
    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body3Bold
        label.textColor = AppColor.blackSprout
        return label
    }()

    private let storeInfoLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.deepSprout
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeNameLabel, storeInfoLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
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
        backgroundColor = AppColor.brightSprout
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = AppColor.deepSprout.cgColor
        clipsToBounds = true

        addSubview(storeImageView)
        addSubview(divider)
        addSubview(textStackView)

        storeImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.size.equalTo(60)
        }
        
        divider.snp.makeConstraints {
            $0.leading.equalTo(storeImageView.snp.trailing)
            $0.verticalEdges.equalToSuperview()
            $0.width.equalTo(1)
        }
        
        textStackView.snp.makeConstraints {
            $0.leading.equalTo(storeImageView.snp.trailing).offset(AppSpacing.smallMedium)
            $0.trailing.equalToSuperview().inset(AppSpacing.smallMedium)
            $0.centerY.equalToSuperview()
        }
        
        self.snp.makeConstraints {
                $0.height.equalTo(60)
            }
    }

    func configure(name: String, infoText: String, imageUrl: String?) {
        storeNameLabel.text = name
        storeInfoLabel.text = infoText
        storeImageView.setImage(url: imageUrl)
    }
}
