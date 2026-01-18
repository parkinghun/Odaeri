//
//  UserProfileViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine

protocol UserProfileCoordinating: AnyObject {
    func showEditProfile()
    func showSettings()
    func showReportOptions(targetUserId: String)
    func showWritePost()
    func showEditPost(postId: String)
    func showChatRoom(roomId: String, title: String?)
    func didFinishLogout()
}

final class UserProfileViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: UserProfileCoordinating?

    private var targetUserId: String
    private let communityRepository: CommunityPostRepository
    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let headerSubject = CurrentValueSubject<UserProfileHeaderViewModel, Never>(
        UserProfileHeaderViewModel.empty
    )
    private let navigationItemSubject = CurrentValueSubject<UserProfileNavigationItem, Never>(.myMenu)
    private var headerNick: String = ""

    private var isMe: Bool {
        guard let myId = UserManager.shared.currentUser?.userId else {
            return targetUserId.isEmpty
        }
        return targetUserId == myId
    }

    init(
        targetUserId: String,
        initialNick: String? = nil,
        initialProfileImage: String? = nil,
        communityRepository: CommunityPostRepository = CommunityPostRepositoryImpl(),
        chatRepository: ChatRepository = ChatRepositoryImpl(),
        userRepository: UserRepository = UserRepositoryImpl()
    ) {
        self.targetUserId = targetUserId
        self.communityRepository = communityRepository
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        super.init()
        if isMe {
            updateHeader(from: UserManager.shared.currentUser, isMe: true)
            navigationItemSubject.send(.myMenu)
        } else {
            updateHeader(
                nick: initialNick ?? "사용자",
                profileImage: initialProfileImage,
                isMe: false
            )
            navigationItemSubject.send(.otherMenu)
        }
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let viewWillAppear: AnyPublisher<Void, Never>
        let primaryButtonTapped: AnyPublisher<Void, Never>
        let moreTapped: AnyPublisher<Void, Never>
        let logoutTapped: AnyPublisher<Void, Never>
        let emptyActionTapped: AnyPublisher<Void, Never>
        let postAction: AnyPublisher<UserProfilePostAction, Never>
    }

    struct Output {
        let header: AnyPublisher<UserProfileHeaderViewModel, Never>
        let navigationItem: AnyPublisher<UserProfileNavigationItem, Never>
        let posts: AnyPublisher<[CommunityPostEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let postsSubject = CurrentValueSubject<[CommunityPostEntity], Never>([])

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.restoreMyProfileIfNeeded {
                    self?.fetchPosts(subject: postsSubject)
                }
            }
            .store(in: &cancellables)

        input.viewWillAppear
            .sink { [weak self] _ in
                guard let self, self.isMe else { return }
                self.restoreMyProfileIfNeeded {
                    self.updateHeader(from: UserManager.shared.currentUser, isMe: self.isMe)
                    self.fetchPosts(subject: postsSubject)
                }
            }
            .store(in: &cancellables)

        input.primaryButtonTapped
            .sink { [weak self] _ in
                guard let self else { return }
                if self.isMe {
                    self.coordinator?.showEditProfile()
                } else {
                    self.createOrOpenChatRoom()
                }
            }
            .store(in: &cancellables)

        input.moreTapped
            .sink { [weak self] _ in
                guard let self else { return }
                self.coordinator?.showReportOptions(targetUserId: self.targetUserId)
            }
            .store(in: &cancellables)

        input.logoutTapped
            .sink { [weak self] _ in
                self?.logout()
            }
            .store(in: &cancellables)

        input.emptyActionTapped
            .sink { [weak self] _ in
                self?.coordinator?.showWritePost()
            }
            .store(in: &cancellables)

        input.postAction
            .sink { [weak self] action in
                self?.handlePostAction(action, postsSubject: postsSubject)
            }
            .store(in: &cancellables)

        postsSubject
            .sink { [weak self] posts in
                guard let self, !self.isMe else { return }
                if let creator = posts.first?.creator {
                    self.updateHeader(
                        nick: creator.nick,
                        profileImage: creator.profileImage,
                        isMe: false
                    )
                }
            }
            .store(in: &cancellables)

        return Output(
            header: headerSubject.eraseToAnyPublisher(),
            navigationItem: navigationItemSubject.eraseToAnyPublisher(),
            posts: postsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func fetchPosts(subject: CurrentValueSubject<[CommunityPostEntity], Never>) {
        guard !targetUserId.isEmpty else { return }
        isLoadingSubject.send(true)

        communityRepository.fetchPostsByUser(
            userId: targetUserId,
            category: nil,
            limit: 30,
            next: nil
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingSubject.send(false)
                if case .failure(let error) = completion {
                    self?.errorSubject.send(error.errorDescription)
                }
            },
            receiveValue: { posts, _ in
                subject.send(posts)
            }
        )
        .store(in: &cancellables)
    }

    private func restoreMyProfileIfNeeded(completion: @escaping () -> Void) {
        guard targetUserId.isEmpty || UserManager.shared.currentUser == nil else {
            completion()
            return
        }

        userRepository.getMyProfile()
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        self?.errorSubject.send(error.errorDescription)
                    }
                    completion()
                },
                receiveValue: { [weak self] user in
                    UserManager.shared.saveUser(user)
                    self?.targetUserId = user.userId
                    self?.updateHeader(from: user, isMe: true)
                    completion()
                }
            )
            .store(in: &cancellables)
    }

    private func updateHeader(from user: UserEntity?, isMe: Bool) {
        let nick = user?.nick ?? "사용자"
        let profileImage = user?.profileImage ?? ""
        updateHeader(nick: nick, profileImage: profileImage, isMe: isMe)
    }

    private func updateHeader(nick: String, profileImage: String?, isMe: Bool) {
        let buttonTitle = isMe ? "프로필 수정" : "채팅하기"
        let buttonColor = isMe ? AppColor.gray30 : AppColor.blackSprout
        let textColor = isMe ? AppColor.gray90 : AppColor.gray0
        headerNick = nick
        let model = UserProfileHeaderViewModel(
            nick: nick,
            profileImageUrl: profileImage,
            primaryButtonTitle: buttonTitle,
            primaryButtonBackgroundColor: buttonColor,
            primaryButtonTitleColor: textColor
        )
        headerSubject.send(model)
    }

    private func createOrOpenChatRoom() {
        chatRepository.createOrGetChatRoom(opponentId: targetUserId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] room in
                    self?.coordinator?.showChatRoom(roomId: room.roomId, title: self?.headerNick)
                }
            )
            .store(in: &cancellables)
    }

    private func handlePostAction(
        _ action: UserProfilePostAction,
        postsSubject: CurrentValueSubject<[CommunityPostEntity], Never>
    ) {
        switch action {
        case .edit(let postId):
            coordinator?.showEditPost(postId: postId)
        case .delete(let postId):
            deletePost(postId, postsSubject: postsSubject)
        }
    }

    private func deletePost(
        _ postId: String,
        postsSubject: CurrentValueSubject<[CommunityPostEntity], Never>
    ) {
        communityRepository.deletePost(postId: postId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { _ in
                    let updated = postsSubject.value.filter { $0.postId != postId }
                    postsSubject.send(updated)
                }
            )
            .store(in: &cancellables)
    }

    private func logout() {
        isLoadingSubject.send(true)

        userRepository.logout()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] _ in
                    TokenManager.shared.clearTokens()
                    UserManager.shared.clearUser()
                    self?.coordinator?.didFinishLogout()
                }
            )
            .store(in: &cancellables)
    }
}

struct UserProfileHeaderViewModel {
    let nick: String
    let profileImageUrl: String?
    let primaryButtonTitle: String
    let primaryButtonBackgroundColor: UIColor
    let primaryButtonTitleColor: UIColor

    static let empty = UserProfileHeaderViewModel(
        nick: "",
        profileImageUrl: "",
        primaryButtonTitle: "",
        primaryButtonBackgroundColor: AppColor.gray30,
        primaryButtonTitleColor: AppColor.gray90
    )
}

enum UserProfileNavigationItem {
    case myMenu
    case otherMenu
}

enum UserProfilePostAction {
    case edit(String)
    case delete(String)
}
