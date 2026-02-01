//
//  NavigationStepCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 02/01/26.
//

import UIKit
import SnapKit

final class NavigationStepCell: UICollectionViewCell {
    static let reuseIdentifier = "NavigationStepCell"

    private let iconImageView = UIImageView()
    private let distanceLabel = UILabel()
    private let instructionLabel = UILabel()
    private let iconStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppColor.gray0

        distanceLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        distanceLabel.textColor = AppColor.gray0

        instructionLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        instructionLabel.textColor = AppColor.gray0
        instructionLabel.numberOfLines = 2

        iconStack.axis = .vertical
        iconStack.alignment = .center
        iconStack.spacing = 4
        iconStack.addArrangedSubview(iconImageView)
        iconStack.addArrangedSubview(distanceLabel)

        contentView.addSubview(iconStack)
        contentView.addSubview(instructionLabel)

        iconImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 28, height: 28))
        }

        iconStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.greaterThanOrEqualTo(44)
        }

        instructionLabel.snp.makeConstraints {
            $0.leading.equalTo(iconStack.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(with step: NavigationRouteStep) {
        iconImageView.image = UIImage(systemName: step.direction.systemImageName)
        distanceLabel.text = step.distanceText
        instructionLabel.text = step.instruction
    }
}
