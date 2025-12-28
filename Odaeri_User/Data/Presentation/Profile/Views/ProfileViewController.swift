//
//  ProfileViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/22/25.
//

import UIKit
import Combine
import SnapKit

final class ProfileViewController: BaseViewController<ProfileViewModel> {
    weak var coordinator: ProfileCoordinator?
    
    private let logoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("로그아웃", for: .normal)
        button.backgroundColor = AppColor.blackSprout
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.layer.cornerRadius = 8
        return button
    }()
    
    override func setupUI() {
        view.addSubview(logoutButton)

        logoutButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(40)
            $0.height.equalTo(50)
        }
    }

    override func bind() {
        super.bind()

        let input = ProfileViewModel.Input(
            logoutButtonTapped: logoutButton.tapPublisher()
        )

        let output = viewModel.transform(input: input)

        output.logoutError
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "로그아웃 실패", message: errorMessage)
            }
            .store(in: &cancellables)

        output.logoutSuccess
            .sink { [weak self] _ in
                self?.coordinator?.didFinishLogout()
            }
            .store(in: &cancellables)
    }
}
