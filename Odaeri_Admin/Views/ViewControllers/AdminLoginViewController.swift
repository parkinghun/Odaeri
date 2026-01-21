//
//  AdminLoginViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class AdminLoginViewController: UIViewController {
    private let viewModel: AdminLoginViewModel
    private var cancellables = Set<AnyCancellable>()

    var onLoginSuccess: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Odaeri Admin"
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
        label.isHidden = true
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
        label.isHidden = true
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그인", for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.backgroundColor = AppColor.blackSprout
        button.layer.cornerRadius = 8
        button.isEnabled = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    init(viewModel: AdminLoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(emailValidationLabel)
        view.addSubview(passwordTextField)
        view.addSubview(passwordValidationLabel)
        view.addSubview(loginButton)
        view.addSubview(activityIndicator)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(100)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(60)
            $0.leading.trailing.equalToSuperview().inset(60)
            $0.height.equalTo(48)
        }

        emailValidationLabel.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(emailTextField).inset(4)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailValidationLabel.snp.bottom).offset(16)
            $0.leading.trailing.height.equalTo(emailTextField)
        }

        passwordValidationLabel.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(passwordTextField).inset(4)
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(passwordValidationLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(50)
        }

        activityIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(loginButton.snp.bottom).offset(20)
        }
    }

    private func bind() {
        let input = AdminLoginViewModel.Input(
            emailText: emailTextField.textPublisher.eraseToAnyPublisher(),
            passwordText: passwordTextField.textPublisher.eraseToAnyPublisher(),
            loginTapped: loginButton.tapPublisher()
        )
        let output = viewModel.transform(input: input)

        output.emailValidationMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.emailValidationLabel.text = message
                self?.emailValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.passwordValidationMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.passwordValidationLabel.text = message
                self?.passwordValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.isLoginEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.loginButton.isEnabled = isEnabled
                self?.loginButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        output.loginError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "로그인 실패", message: message)
            }
            .store(in: &cancellables)

        output.loginSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.onLoginSuccess?()
            }
            .store(in: &cancellables)
    }
}

private extension AdminLoginViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
