//
//  ChatRoomEmptyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit

final class ChatRoomEmptyView: UIView {
    private let actionTappedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    var actionTapped: AnyPublisher<Void, Never> {
        actionTappedSubject.eraseToAnyPublisher()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 대화 중인 친구가 없어요."
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "커뮤니티에서 관심사가 비슷한 유저에게 \n먼저 인사를 건네보세요!"
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton()
        button.setTitle("커뮤니티 구경하기", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.backgroundColor = AppColor.blackSprout
        button.layer.cornerRadius = 12
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, actionButton])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.medium
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

        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.screenMargin)
        }

        actionButton.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.greaterThanOrEqualTo(180)
        }

        actionButton.tapPublisher()
            .sink { [weak self] _ in
                self?.actionTappedSubject.send(())
            }
            .store(in: &cancellables)
    }
}
