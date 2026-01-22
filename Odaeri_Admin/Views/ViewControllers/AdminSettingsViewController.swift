//
//  AdminSettingsViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import UIKit
import Combine
import SnapKit

final class AdminSettingsViewController: UIViewController {
    private let authService: AdminAuthService
    private var cancellables = Set<AnyCancellable>()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let storeIdField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let accountTitleLabel = UILabel()
    private let accountInfoLabel = UILabel()
    private let logoutButton = UIButton(type: .system)

    var onStoreIdUpdated: (() -> Void)?

    init(authService: AdminAuthService = AdminAuthService()) {
        self.authService = authService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStoreId()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        title = "설정"

        titleLabel.text = "가게 ID 설정"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        infoLabel.text = "서버에서 받은 storeId를 입력하세요."
        infoLabel.font = AppFont.caption1
        infoLabel.textColor = AppColor.gray60

        storeIdField.borderStyle = .roundedRect
        storeIdField.placeholder = "storeId"
        storeIdField.autocapitalizationType = .none
        storeIdField.autocorrectionType = .no
        storeIdField.font = AppFont.body2
        storeIdField.textColor = AppColor.gray90

        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(AppColor.gray0, for: .normal)
        saveButton.backgroundColor = AppColor.deepSprout
        saveButton.layer.cornerRadius = Layout.buttonCornerRadius
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        clearButton.setTitle("초기화", for: .normal)
        clearButton.setTitleColor(AppColor.gray90, for: .normal)
        clearButton.backgroundColor = AppColor.gray30
        clearButton.layer.cornerRadius = Layout.buttonCornerRadius
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)

        accountTitleLabel.text = "계정"
        accountTitleLabel.font = AppFont.body1Bold
        accountTitleLabel.textColor = AppColor.gray90

        accountInfoLabel.font = AppFont.body2
        accountInfoLabel.textColor = AppColor.gray75
        accountInfoLabel.numberOfLines = 0

        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.setTitleColor(AppColor.gray0, for: .normal)
        logoutButton.backgroundColor = AppColor.gray90
        logoutButton.layer.cornerRadius = Layout.buttonCornerRadius
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [saveButton, clearButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = Layout.buttonSpacing
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            infoLabel,
            storeIdField,
            buttonStack,
            accountTitleLabel,
            accountInfoLabel,
            logoutButton
        ])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing

        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Layout.pageInset)
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
        }

        clearButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
        }

        logoutButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
        }
    }

    private func loadStoreId() {
        storeIdField.text = AdminStoreSession.shared.storeId
        if let user = UserManager.shared.currentUser {
            accountInfoLabel.text = "\(user.email)\n\(user.nick)"
        } else {
            accountInfoLabel.text = "로그인 정보가 없습니다."
        }
    }

    @objc private func handleSave() {
        let trimmed = storeIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return }
        AdminStoreSession.shared.storeId = trimmed
        onStoreIdUpdated?()
        dismiss(animated: true)
    }

    @objc private func handleClear() {
        AdminStoreSession.shared.clearStoreId()
        onStoreIdUpdated?()
        dismiss(animated: true)
    }

    @objc private func handleLogout() {
        let alert = UIAlertController(
            title: "로그아웃",
            message: "로그아웃 하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        logoutButton.isEnabled = false
        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.logoutButton.isEnabled = true
                    if case .failure(let error) = completion {
                        self.showAlert(title: "로그아웃 실패", message: error.errorDescription)
                    }
                    TokenManager.shared.clearTokens()
                    AdminStoreSession.shared.clearStoreId()
                    self.dismiss(animated: true)
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private enum Layout {
    static let pageInset: CGFloat = 24
    static let sectionSpacing: CGFloat = 12
    static let buttonSpacing: CGFloat = 12
    static let buttonHeight: CGFloat = 44
    static let buttonCornerRadius: CGFloat = 12
}
