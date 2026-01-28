//
//  UserProfileEditViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation
import Combine

final class UserProfileEditViewModel: BaseViewModel, ViewModelType {
    private let userRepository: UserRepository
    private let currentNick = CurrentValueSubject<String, Never>("")
    private let selectedImageData = CurrentValueSubject<Data?, Never>(nil)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let didUpdateSubject = PassthroughSubject<Void, Never>()
    private let initialNickSubject = CurrentValueSubject<String, Never>("")
    private let initialProfileImageSubject = CurrentValueSubject<String, Never>("")

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nickText: AnyPublisher<String, Never>
        let imageData: AnyPublisher<Data?, Never>
        let saveTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let initialNick: AnyPublisher<String, Never>
        let initialProfileImageUrl: AnyPublisher<String, Never>
        let nickValidationMessage: AnyPublisher<String, Never>
        let isSaveEnabled: AnyPublisher<Bool, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let didUpdate: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self else { return }
                let user = UserManager.shared.currentUser
                self.initialNickSubject.send(user?.nick ?? "")
                self.initialProfileImageSubject.send(user?.profileImage ?? "")
                self.currentNick.send(user?.nick ?? "")
            }
            .store(in: &cancellables)

        input.nickText
            .sink { [weak self] nick in
                self?.currentNick.send(nick)
            }
            .store(in: &cancellables)

        input.imageData
            .sink { [weak self] data in
                self?.selectedImageData.send(data)
            }
            .store(in: &cancellables)

        let nickValidation = currentNick
            .map { InputValidator.nicknameValidationMessage(for: $0) ?? "" }
            .eraseToAnyPublisher()

        let isSaveEnabled = Publishers.CombineLatest(
            currentNick.map { InputValidator.validateNickname($0) },
            isLoadingSubject
        )
        .map { isNickValid, isLoading in
            isNickValid && !isLoading
        }
        .eraseToAnyPublisher()

        input.saveTapped
            .sink { [weak self] _ in
                self?.saveProfile()
            }
            .store(in: &cancellables)

        return Output(
            initialNick: initialNickSubject.eraseToAnyPublisher(),
            initialProfileImageUrl: initialProfileImageSubject.eraseToAnyPublisher(),
            nickValidationMessage: nickValidation,
            isSaveEnabled: isSaveEnabled,
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            didUpdate: didUpdateSubject.eraseToAnyPublisher()
        )
    }
}

private extension UserProfileEditViewModel {
    func saveProfile() {
        let nick = currentNick.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard InputValidator.validateNickname(nick) else {
            errorSubject.send("닉네임을 확인해주세요.")
            return
        }

        isLoadingSubject.send(true)

        let uploadPublisher: AnyPublisher<String?, NetworkError>
        if let imageData = selectedImageData.value {
            uploadPublisher = userRepository.uploadProfileImage(imageData: imageData)
                .map { Optional($0) }
                .eraseToAnyPublisher()
        } else {
            uploadPublisher = Just<String?>(nil)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        uploadPublisher
            .flatMap { [weak self] profileImage -> AnyPublisher<UserEntity, NetworkError> in
                guard let self else {
                    return Fail(error: NetworkError.unknown(nil)).eraseToAnyPublisher()
                }
                return self.userRepository.updateMyProfile(
                    nick: nick,
                    phoneNum: nil,
                    profileImage: profileImage
                )
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] user in
                    UserManager.shared.saveUser(user)
                    self?.didUpdateSubject.send(())
                }
            )
            .store(in: &cancellables)
    }
}
