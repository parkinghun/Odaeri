//
//  USerRepository.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import Foundation
import Combine

protocol UserRepository {
    func emailLogin(email: String, password: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError>
    func kakaoLogin(deviceToken: String) -> AnyPublisher<UserResult, NetworkError>
    func appleLogin(deviceToken: String) -> AnyPublisher<UserResult, NetworkError>
    func getMyProfile() -> AnyPublisher<UserEntity, NetworkError>
    func searchUsers(nick: String) -> AnyPublisher<[UserSearchResult], NetworkError>
    func logout() -> AnyPublisher<Void, NetworkError>
    func validateEmail(email: String) -> AnyPublisher<Void, NetworkError>
    func join(email: String, password: String, nick: String, phoneNum: String, deviceToken: String) -> AnyPublisher<UserResult, NetworkError>
    func uploadProfileImage(imageData: Data) -> AnyPublisher<String, NetworkError>
    func updateMyProfile(nick: String?, phoneNum: String?, profileImage: String?) -> AnyPublisher<UserEntity, NetworkError>
}
