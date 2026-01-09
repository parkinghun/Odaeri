//
//  UserProfileEmptyView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit

final class UserProfileEmptyView: UIView {
    private let actionTappedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    var actionTapped: AnyPublisher<Void, Never> {
        actionTappedSubject.eraseToAnyPublisher()
    }

    private let messageLabel = UILabel()
    private let actionButton = UIButton()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageLabel, actionButton])
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

    func configure(isMe: Bool) {
        if isMe {
            messageLabel.text = "아직 기록이 없어요. 첫 번째 맛집을 공유해보세요!"
            actionButton.isHidden = false
        } else {
            messageLabel.text = "아직 작성한 게시글이 없습니다."
            actionButton.isHidden = true
        }
    }

    private func setupUI() {
        addSubview(stackView)

        messageLabel.font = AppFont.body2
        messageLabel.textColor = AppColor.gray75
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        actionButton.layer.cornerRadius = 12
        actionButton.titleLabel?.font = AppFont.body2Bold
        actionButton.setTitle("글쓰기", for: .normal)
        actionButton.setTitleColor(AppColor.gray0, for: .normal)
        actionButton.backgroundColor = AppColor.blackSprout

        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.screenMargin)
        }

        actionButton.snp.makeConstraints {
            $0.height.equalTo(40)
            $0.width.greaterThanOrEqualTo(120)
        }

        actionButton.tapPublisher()
            .sink { [weak self] _ in
                self?.actionTappedSubject.send(())
            }
            .store(in: &cancellables)
    }
}
