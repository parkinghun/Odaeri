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

    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "이메일을 입력해주세요"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    private let emailValidationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()

    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "비밀번호를 입력해주세요"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    private let passwordValidationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("로그인", for: .normal)
        button.backgroundColor = AppColor.blackSprout
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.layer.cornerRadius = 8
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = AppColor.blackSprout
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func setupUI() {
        super.setupUI()

        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(emailValidationLabel)
        view.addSubview(passwordTextField)
        view.addSubview(passwordValidationLabel)
        view.addSubview(loginButton)
        view.addSubview(loadingIndicator)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(100)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(60)
            $0.leading.equalToSuperview().offset(40)
            $0.trailing.equalToSuperview().offset(-40)
            $0.height.equalTo(48)
        }

        emailValidationLabel.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(4)
            $0.leading.equalTo(emailTextField).offset(4)
            $0.trailing.equalTo(emailTextField).offset(-4)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailValidationLabel.snp.bottom).offset(16)
            $0.leading.trailing.height.equalTo(emailTextField)
        }

        passwordValidationLabel.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(4)
            $0.leading.equalTo(passwordTextField).offset(4)
            $0.trailing.equalTo(passwordTextField).offset(-4)
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(passwordValidationLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(50)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }

    override func bind() {
        super.bind()

        let emailTextPublisher = emailTextField.textPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()

        let passwordTextPublisher = passwordTextField.textPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()

        let input = LoginViewModel.Input(
            emailText: emailTextPublisher,
            passwordText: passwordTextPublisher,
            loginButtonTapped: loginButtonTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.emailValidationMessage
            .sink { [weak self] message in
                self?.emailValidationLabel.text = message
                self?.emailValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.passwordValidationMessage
            .sink { [weak self] message in
                self?.passwordValidationLabel.text = message
                self?.passwordValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.isLoginEnabled
            .sink { [weak self] isEnabled in
                self?.loginButton.isEnabled = isEnabled
                self?.loginButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.view.isUserInteractionEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.view.isUserInteractionEnabled = true
                }
            }
            .store(in: &cancellables)

        output.loginError
            .sink { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            }
            .store(in: &cancellables)

        output.loginSuccess
            .sink { [weak self] _ in
                self?.coordinator?.didFinishLogin()
            }
            .store(in: &cancellables)
    }

    @objc private func loginButtonTapped() {
        loginButtonTappedSubject.send(())
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "로그인 실패",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
