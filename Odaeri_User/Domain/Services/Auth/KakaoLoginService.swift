//
//  KakaoLoginService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/19/26.
//

import KakaoSDKUser
import KakaoSDKAuth
import Combine

protocol KakaoLoginServiceProtocol {
    func login() -> AnyPublisher<OAuthToken, Error>
}

final class DefaultKakaoLoginService: KakaoLoginServiceProtocol {
    
    func login() -> AnyPublisher<OAuthToken, Error> {
        Future<OAuthToken, Error> { promise in
            if (UserApi.isKakaoTalkLoginAvailable()) {  // 1. 카카오톡 설치 여부 확인
                UserApi.shared.loginWithKakaoTalk { (token, error) in  // 2. 카카오톡으로 로그인
                    if let error = error {
                        promise(.failure(error))
                    } else if let token = token {
                        promise(.success(token))
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { (token, error) in  // 3. 카카오계정으로 로그인(웹 브라우저)
                    if let error = error {
                        promise(.failure(error))
                    } else if let token = token {
                        promise(.success(token))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func logout() {
        UserApi.shared.logout { (error) in
            if let error = error {
                print("카카오 SDK 로그아웃 실패: \(error)")
            } else {
                print("카카오 SDK 로그아웃 성공")
                // 여기서 우리 서버 로그아웃 API 호출 및 자동로그인 정보 삭제
            }
        }
    }
}
