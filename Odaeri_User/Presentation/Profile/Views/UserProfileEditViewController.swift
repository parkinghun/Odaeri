//
//  UserProfileEditViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import Combine
import SnapKit
import PhotosUI

final class UserProfileEditViewController: BaseViewController<UserProfileEditViewModel> {
    private let profileImageView = UIImageView()
    private let nickTextField = UITextField()
    private let nickValidationLabel = UILabel()
    private let saveButton = UIButton()
    private let imageDataSubject = CurrentValueSubject<Data?, Never>(nil)

    override var navigationBarHidden: Bool { false }

    override func setupUI() {
        super.setupUI()

        navigationItem.title = "프로필 수정"
        view.backgroundColor = AppColor.gray0

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 48
        profileImageView.backgroundColor = AppColor.gray15
        profileImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectProfileImage))
        profileImageView.addGestureRecognizer(tapGesture)

        nickTextField.placeholder = "닉네임을 입력해주세요"
        nickTextField.borderStyle = .roundedRect
        nickTextField.autocapitalizationType = .none
        nickTextField.autocorrectionType = .no

        nickValidationLabel.font = AppFont.caption1
        nickValidationLabel.textColor = .systemRed
        nickValidationLabel.numberOfLines = 0

        saveButton.setTitle("저장", for: .normal)
        saveButton.backgroundColor = AppColor.blackSprout
        saveButton.setTitleColor(AppColor.gray0, for: .normal)
        saveButton.titleLabel?.font = AppFont.body1
        saveButton.layer.cornerRadius = 8

        view.addSubview(profileImageView)
        view.addSubview(nickTextField)
        view.addSubview(nickValidationLabel)
        view.addSubview(saveButton)

        profileImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(96)
        }

        nickTextField.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(40)
            $0.trailing.equalToSuperview().offset(-40)
            $0.height.equalTo(48)
        }

        nickValidationLabel.snp.makeConstraints {
            $0.top.equalTo(nickTextField.snp.bottom).offset(4)
            $0.leading.equalTo(nickTextField).offset(4)
            $0.trailing.equalTo(nickTextField).offset(-4)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(nickValidationLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalTo(nickTextField)
            $0.height.equalTo(50)
        }
    }

    override func bind() {
        super.bind()

        let input = UserProfileEditViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            nickText: nickTextField.textPublisher.compactMap { $0 }.eraseToAnyPublisher(),
            imageData: imageDataSubject.eraseToAnyPublisher(),
            saveTapped: saveButton.tapPublisher()
        )

        let output = viewModel.transform(input: input)

        output.initialNick
            .sink { [weak self] nick in
                self?.nickTextField.text = nick
            }
            .store(in: &cancellables)

        output.initialProfileImageUrl
            .sink { [weak self] url in
                self?.profileImageView.resetImage(placeholder: AppImage.person)
                if !url.isEmpty {
                    self?.profileImageView.setImage(url: url, placeholder: AppImage.person)
                }
            }
            .store(in: &cancellables)

        output.nickValidationMessage
            .sink { [weak self] message in
                self?.nickValidationLabel.text = message
                self?.nickValidationLabel.isHidden = message.isEmpty
            }
            .store(in: &cancellables)

        output.isSaveEnabled
            .sink { [weak self] isEnabled in
                self?.saveButton.isEnabled = isEnabled
                self?.saveButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .sink { [weak self] in
                self?.setLoading($0)
            }
            .store(in: &cancellables)

        output.error
            .sink { [weak self] message in
                self?.showAlert(title: "프로필 수정 실패", message: message)
            }
            .store(in: &cancellables)

        output.didUpdate
            .sink { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func selectProfileImage() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension UserProfileEditViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self else { return }
            guard let image = object as? UIImage else { return }
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }

            DispatchQueue.main.async {
                self.profileImageView.image = image
                self.imageDataSubject.send(data)
            }
        }
    }
}
