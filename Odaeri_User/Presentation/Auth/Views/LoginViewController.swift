//
//  LoginViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit
import Combine
import SnapKit

final class LoginViewController: BaseViewController {
    weak var coordinator: AuthCoordinator?

    private let viewModel = LoginViewModel()
    private let loginButtonTappedSubject = PassthroughSubject<Void, Never>()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Odaeri"
        label.font = AppFont.brandTitle1
        label.textColor = AppColor.blackSprout
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("로그인 (임시)", for: .normal)
        button.backgroundColor = AppColor.blackSprout
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.layer.cornerRadius = 8
        return button
    }()

    override func setupUI() {
        super.setupUI()

        view.addSubview(titleLabel)
        view.addSubview(loginButton)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-100)
        }

        loginButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(60)
            $0.leading.equalToSuperview().offset(40)
            $0.trailing.equalToSuperview().offset(-40)
            $0.height.equalTo(50)
        }

        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }

    override func bind() {
        super.bind()

        let input = LoginViewModel.Input(
            loginButtonTapped: loginButtonTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.loginSuccess
            .sink { [weak self] _ in
                self?.coordinator?.didFinishLogin()
            }
            .store(in: &cancellables)
    }

    @objc private func loginButtonTapped() {
        loginButtonTappedSubject.send(())
    }
}
