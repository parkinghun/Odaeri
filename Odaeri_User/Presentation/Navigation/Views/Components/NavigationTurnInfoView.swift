//
//  NavigationTurnInfoView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 02/01/26.
//

import UIKit
import SnapKit

final class NavigationTurnInfoView: UIView {
    private let iconContainer = UIView()
    private let directionImageView = UIImageView()
    private let distanceLabel = UILabel()
    private let instructionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12

        iconContainer.backgroundColor = AppColor.brightSprout
        iconContainer.layer.cornerRadius = 18

        directionImageView.contentMode = .scaleAspectFit
        directionImageView.tintColor = AppColor.blackSprout

        distanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        distanceLabel.textColor = AppColor.blackSprout

        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        instructionLabel.textColor = AppColor.gray90
        instructionLabel.numberOfLines = 2

        addSubview(iconContainer)
        iconContainer.addSubview(directionImageView)
        addSubview(distanceLabel)
        addSubview(instructionLabel)

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 52, height: 52))
        }

        directionImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 30, height: 30))
        }

        distanceLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        instructionLabel.snp.makeConstraints {
            $0.leading.equalTo(distanceLabel)
            $0.top.equalTo(distanceLabel.snp.bottom).offset(8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
        }
    }

    func update(with info: NavigationTurnInfo) {
        distanceLabel.text = info.distanceText
        instructionLabel.text = info.instructionText
        directionImageView.image = UIImage(systemName: info.direction.systemImageName)
    }
}
