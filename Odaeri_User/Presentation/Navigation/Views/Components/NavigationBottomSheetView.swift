//
//  NavigationBottomSheetView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 02/01/26.
//

import UIKit
import SnapKit

final class NavigationBottomSheetView: UIView {
    private let infoStack = UIStackView()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 12

        infoStack.axis = .vertical
        infoStack.spacing = 4

        timeLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        timeLabel.textColor = AppColor.blackSprout

        distanceLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        distanceLabel.textColor = AppColor.gray75

        infoStack.addArrangedSubview(timeLabel)
        infoStack.addArrangedSubview(distanceLabel)

        addSubview(infoStack)

        infoStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func update(timeText: String, distanceText: String) {
        timeLabel.text = timeText
        distanceLabel.text = "남은 거리 \(distanceText)"
    }
}
