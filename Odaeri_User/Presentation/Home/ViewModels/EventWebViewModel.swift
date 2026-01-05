//
//  EventWebViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/4/26.
//

import Foundation
import Combine

final class EventWebViewModel: BaseViewModel, ViewModelType {
    private let path: String
    private let bannerRepository: BannerRepository

    init(path: String, bannerRepository: BannerRepository = BannerRepositoryImpl()) {
        self.path = path
        self.bannerRepository = bannerRepository
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let attendanceButtonClicked: AnyPublisher<Void, Never>
        let attendanceCompleted: AnyPublisher<String, Never>
    }

    struct Output {
        let urlRequest: AnyPublisher<URLRequest, Never>
        let executeJavaScript: AnyPublisher<String, Never>
        let showAlert: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        // 1. URL Request 생성 (WebViewManager 사용)
        let urlRequestPublisher = input.viewDidLoad
            .compactMap { [weak self] _ -> URLRequest? in
                guard let self = self else { return nil }
                return WebViewManager.shared.createURLRequest(for: self.path)
            }
            .eraseToAnyPublisher()

        // 2. 출석 버튼 클릭 시 → JavaScript 실행 요청
        // Repository에서 accessToken을 가져와서 requestAttendance('토큰') 형태로 전달
        let executeJSPublisher = input.attendanceButtonClicked
            .compactMap { [weak self] _ -> String? in
                guard let self = self else { return nil }

                // BannerRepository를 통해 accessToken 가져오기
                let token = self.bannerRepository.getAccessToken() ?? ""

                // JavaScript 함수 호출 문자열 생성
                // webView.evaluateJavaScript("requestAttendance('\(accessToken)')")
                return "requestAttendance('\(token)')"
            }
            .eraseToAnyPublisher()

        // 3. 출석 완료 시 → 알럿 메시지 방출
        // message.body에 출석 횟수가 포함되어 있음
        let showAlertPublisher = input.attendanceCompleted
            .map { attendanceCount in
                return "출석 완료! 현재 출석 횟수: \(attendanceCount)회"
            }
            .eraseToAnyPublisher()

        return Output(
            urlRequest: urlRequestPublisher,
            executeJavaScript: executeJSPublisher,
            showAlert: showAlertPublisher
        )
    }
}
