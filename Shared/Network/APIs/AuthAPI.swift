//
//  AuthAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum AuthAPI {
    case validateEmail(request: EmailValidationRequest)
    case join(request: JoinRequest)
    case emailLogin(request: EmailLoginRequest)
    case kakaoLogin(request: KakaoLoginRequest)
    case appleLogin(request: AppleLoginRequest)
    case logout
    case updateDeviceToken(request: DeviceTokenRequest)
    case getMyProfile
    case updateMyProfile(request: ProfileUpdateRequest)
    case uploadProfileImage(imageData: Data)
    case searchUsers(nick: String)
}

extension AuthAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .validateEmail:
            return "/users/validation/email"
        case .join:
            return "/users/join"
        case .emailLogin:
            return "/users/login"
        case .kakaoLogin:
            return "/users/login/kakao"
        case .appleLogin:
            return "/users/login/apple"
        case .logout:
            return "/users/logout"
        case .updateDeviceToken:
            return "/users/deviceToken"
        case .getMyProfile:
            return "/users/me/profile"
        case .updateMyProfile:
            return "/users/me/profile"
        case .uploadProfileImage:
            return "/users/profile/image"
        case .searchUsers:
            return "/users/search"
        }
    }

    var method: Moya.Method {
        switch self {
        case .validateEmail, .join, .emailLogin, .kakaoLogin, .appleLogin, .logout, .uploadProfileImage:
            return .post
        case .updateDeviceToken, .updateMyProfile:
            return .put
        case .getMyProfile, .searchUsers:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .validateEmail(let request):
            return .requestJSONEncodable(request)

        case .join(let request):
            return .requestJSONEncodable(request)

        case .emailLogin(let request):
            return .requestJSONEncodable(request)

        case .kakaoLogin(let request):
            return .requestJSONEncodable(request)

        case .appleLogin(let request):
            return .requestJSONEncodable(request)

        case .logout:
            return .requestPlain

        case .updateDeviceToken(let request):
            return .requestJSONEncodable(request)

        case .getMyProfile:
            return .requestPlain

        case .updateMyProfile(let request):
            return .requestJSONEncodable(request)

        case .uploadProfileImage(let imageData):
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "profile",
                fileName: "profile_image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])

        case .searchUsers(let nick):
            return .requestParameters(
                parameters: ["nick": nick],
                encoding: URLEncoding.queryString
            )
        }
    }
}
