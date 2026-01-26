//
//  UserManager.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import Foundation
import Combine

final class UserManager {
    static let shared = UserManager()

    private init() {
        loadUser()
    }

    @Published private(set) var currentUser: UserEntity?

    var currentUserPublisher: AnyPublisher<UserEntity?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private enum UserDefaultsKey {
        static let userId = "userId"
        static let email = "email"
        static let nick = "nick"
        static let profileImage = "profileImage"
    }

    func saveUser(_ user: UserEntity) {
        currentUser = user
        UserDefaults.standard.set(user.userId, forKey: UserDefaultsKey.userId)
        UserDefaults.standard.set(user.email, forKey: UserDefaultsKey.email)
        UserDefaults.standard.set(user.nick, forKey: UserDefaultsKey.nick)
        UserDefaults.standard.set(user.profileImage, forKey: UserDefaultsKey.profileImage)
        RealmDefaultConfigurationManager.shared.applyDefaultConfiguration(for: user.userId)
    }

    func loadUser() {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultsKey.userId),
              let email = UserDefaults.standard.string(forKey: UserDefaultsKey.email),
              let nick = UserDefaults.standard.string(forKey: UserDefaultsKey.nick) else {
            currentUser = nil
            return
        }

        let profileImage = UserDefaults.standard.string(forKey: UserDefaultsKey.profileImage) ?? ""

        currentUser = UserEntity(
            userId: userId,
            email: email,
            nick: nick,
            profileImage: profileImage,
            phoneNum: nil
        )
        
        print("👏 currentUser: ")
        dump(currentUser)
    }

    func clearUser() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.userId)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.email)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.nick)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.profileImage)
    }
}

extension UserManager: SessionProviding {
    var currentUserId: String? {
        currentUser?.userId
    }
}
