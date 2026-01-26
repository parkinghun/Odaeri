//
//  LoginViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit
import Combine
import SnapKit
import AuthenticationServices

final class LoginViewController: BaseViewController<LoginViewModel> {
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
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        let text = "오대리가 처음이신가요? 회원가입"
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(.foregroundColor, value: AppColor.blackSprout, range: NSRange(location: 0, length: text.count))
        let highlightRange = (text as NSString).range(of: "회원가입")
        attributed.addAttribute(.foregroundColor, value: AppColor.blackSprout, range: highlightRange)
        attributed.addAttribute(.font, value: AppFont.body2Bold, range: highlightRange)
        attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: highlightRange)
        button.setAttributedTitle(attributed, for: .normal)
        return button
    }()

    private let socialDividerLeft: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.blackSprout
        return view
    }()

    private let socialDividerRight: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.blackSprout
        return view
    }()

    private let socialDividerLabel: UILabel = {
        let label = UILabel()
        label.text = "SNS 계정으로 로그인하세요"
        label.font = AppFont.caption1
        label.textColor = AppColor.blackSprout
        return label
    }()

    private let kakaoLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(AppImage.kakaoLogin, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        button.backgroundColor = .clear
        button.layer.cornerRadius = 30
        return button
    }()

    private let appleLoginButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        button.setImage(AppImage.appleLogo.withConfiguration(config), for: .normal)
        button.tintColor = AppColor.gray0
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .black
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        return button
    }()

    private let socialLoginStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 24
        return stackView
    }()
    
    override func setupUI() {
        super.setupUI()

        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(emailValidationLabel)
        view.addSubview(passwordTextField)
        view.addSubview(passwordValidationLabel)
        view.addSubview(loginButton)
        view.addSubview(socialDividerLeft)
        view.addSubview(socialDividerLabel)
        view.addSubview(socialDividerRight)
        view.addSubview(socialLoginStackView)
        socialLoginStackView.addArrangedSubview(appleLoginButton)
        socialLoginStackView.addArrangedSubview(kakaoLoginButton)
        view.addSubview(signUpButton)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(100)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(60)
            $0.horizontalEdges.equalToSuperview().inset(40)
            $0.height.equalTo(48)
        }

        emailValidationLabel.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(4)
            $0.leading.equalTo(emailTextField).offset(4)
            $0.trailing.equalTo(emailTextField).offset(-4)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailValidationLabel.snp.bottom).offset(16)
            $0.horizontalEdges.height.equalTo(emailTextField)
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
        
        signUpButton.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(AppSpacing.smallMedium)
            $0.centerX.equalToSuperview()
        }

        socialDividerLabel.snp.makeConstraints {
            $0.top.equalTo(signUpButton.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
        }

        socialDividerLeft.snp.makeConstraints {
            $0.centerY.equalTo(socialDividerLabel)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(socialDividerLabel.snp.leading).offset(-12)
            $0.height.equalTo(1)
        }

        socialDividerRight.snp.makeConstraints {
            $0.centerY.equalTo(socialDividerLabel)
            $0.leading.equalTo(socialDividerLabel.snp.trailing).offset(12)
            $0.trailing.equalTo(emailTextField)
            $0.height.equalTo(1)
        }

        socialLoginStackView.snp.makeConstraints {
            $0.top.equalTo(socialDividerLabel.snp.bottom).offset(AppSpacing.xLarge)
            $0.centerX.equalToSuperview()
        }

        kakaoLoginButton.snp.makeConstraints {
            $0.size.equalTo(60)
        }

        appleLoginButton.snp.makeConstraints {
            $0.size.equalTo(60)
        }
    }

    override func bind() {
        super.bind()

        let input = LoginViewModel.Input(
            emailText: emailTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            passwordText: passwordTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            loginButtonTapped: loginButton.tapPublisher(),
            kakaoLoginTapped: kakaoLoginButton.tapPublisher(),
            appleLoginTapped: appleLoginButton.tapPublisher(),
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

        output.isLoginEnabled
            .sink { [weak self] isEnabled in
                self?.loginButton.isEnabled = isEnabled
                self?.loginButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .sink { [weak self] in
                self?.setLoading($0)
            }
            .store(in: &cancellables)

        output.loginError
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "로그인 실패", message: errorMessage)
            }
            .store(in: &cancellables)

    }
}
