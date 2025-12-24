//
//  LocationView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class LocationView: BaseView {
    private let locationText: String

    private let tapSubject = PassthroughSubject<Void, Never>()
    var tapPublisher: AnyPublisher<Void, Never> {
        tapSubject.eraseToAnyPublisher()
    }

    private let locationImageView: UIImageView = {
        let imageView = UIImageView(image: AppImage.location)
        return imageView
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = locationText
        label.font = AppFont.body1
        label.textColor = AppColor.gray90
        return label
    }()

    private lazy var detailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(AppImage.detail, for: .normal)
        button.tintColor = AppColor.gray75
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [locationImageView, locationLabel, detailButton])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    init(locationText: String = "문래역, 영등포구(위치)") {
        self.locationText = locationText
        super.init(frame: .zero)
    }

    override func setupView() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        locationImageView.snp.makeConstraints {
            $0.size.equalTo(24)
        }

        detailButton.snp.makeConstraints {
            $0.size.equalTo(24)
        }
    }

    @objc private func handleTap() {
        tapSubject.send()
    }
}
