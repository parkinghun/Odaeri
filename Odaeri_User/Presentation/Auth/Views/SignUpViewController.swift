//
//  SignUpViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import Combine
import SnapKit

final class SignUpViewController: BaseViewController<SignUpViewModel> {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "회원가입"
        label.font = AppFont.title1
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

    private let nickTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "닉네임을 입력해주세요"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    private let nickValidationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()

    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "휴대폰 번호 (선택)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        return textField
    }()

    private let signUpButton: UIButton = {
        let button = UIButton()
        button.setTitle("회원가입", for: .normal)
        button.backgroundColor = AppColor.blackSprout
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.layer.cornerRadius = 8
        return button
    }()

    override func setupUI() {
        super.setupUI()

        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(emailValidationLabel)
        view.addSubview(passwordTextField)
        view.addSubview(passwordValidationLabel)
        view.addSubview(nickTextField)
        view.addSubview(nickValidationLabel)
        view.addSubview(phoneTextField)
        view.addSubview(signUpButton)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
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

        nickTextField.snp.makeConstraints {
            $0.top.equalTo(passwordValidationLabel.snp.bottom).offset(16)
            $0.leading.trailing.height.equalTo(emailTextField)
        }

        nickValidationLabel.snp.makeConstraints {
            $0.top.equalTo(nickTextField.snp.bottom).offset(4)
            $0.leading.equalTo(nickTextField).offset(4)
            $0.trailing.equalTo(nickTextField).offset(-4)
        }

        phoneTextField.snp.makeConstraints {
            $0.top.equalTo(nickValidationLabel.snp.bottom).offset(16)
            $0.leading.trailing.height.equalTo(emailTextField)
        }

        signUpButton.snp.makeConstraints {
            $0.top.equalTo(phoneTextField.snp.bottom).offset(32)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(50)
        }
    }

    override func bind() {
        super.bind()

        let input = SignUpViewModel.Input(
            emailText: emailTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            passwordText: passwordTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            nickText: nickTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            phoneText: phoneTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            signUpTapped: signUpButton.tapPublisher()
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

        output.nickValidationMessage
            .sink { [weak self] message in
                self?.nickValidationLabel.text = message
                self?.nickValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.isSignUpEnabled
            .sink { [weak self] isEnabled in
                self?.signUpButton.isEnabled = isEnabled
                self?.signUpButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .sink { [weak self] in
                self?.setLoading($0)
            }
            .store(in: &cancellables)

        output.signUpError
            .sink { [weak self] message in
                self?.showAlert(title: "회원가입 실패", message: message)
            }
            .store(in: &cancellables)
    }
}
