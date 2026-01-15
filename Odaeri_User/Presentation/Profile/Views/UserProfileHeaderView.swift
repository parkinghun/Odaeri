//
//  UserProfileHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit

final class UserProfileHeaderView: UIView {
    private let actionTappedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    var actionTapped: AnyPublisher<Void, Never> {
        actionTappedSubject.eraseToAnyPublisher()
    }

    private let profileImageView = UIImageView()
    private let nickLabel = UILabel()
    private let actionButton = UIButton()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, nickLabel, actionButton])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.medium
        stackView.alignment = .center
        return stackView
    }()

    private enum Layout {
        static let profileSize: CGFloat = 80
        static let buttonHeight: CGFloat = 40
        static let buttonWidth: CGFloat = 140
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = Layout.profileSize / 2
        profileImageView.backgroundColor = AppColor.gray15

        nickLabel.font = AppFont.body1Bold
        nickLabel.textColor = AppColor.gray90
        nickLabel.textAlignment = .center
        nickLabel.numberOfLines = 1

        actionButton.layer.cornerRadius = 10
        actionButton.titleLabel?.font = AppFont.body2Bold

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.profileSize)
        }

        actionButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
            $0.width.greaterThanOrEqualTo(Layout.buttonWidth)
        }

        actionButton.tapPublisher()
            .sink { [weak self] _ in
                self?.actionTappedSubject.send(())
            }
            .store(in: &cancellables)
    }

    func configure(with viewModel: UserProfileHeaderViewModel) {
        nickLabel.text = viewModel.nick
        actionButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        actionButton.setTitleColor(viewModel.primaryButtonTitleColor, for: .normal)
        actionButton.backgroundColor = viewModel.primaryButtonBackgroundColor
        profileImageView.resetImage(placeholder: AppImage.person)
        profileImageView.setImage(url: viewModel.profileImageUrl, placeholder: AppImage.person)
    }
}
