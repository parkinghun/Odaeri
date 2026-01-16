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
    private let attendanceService: AttendanceServiceProtocol

    init(
        path: String,
        bannerRepository: BannerRepository = BannerRepositoryImpl(),
        attendanceService: AttendanceServiceProtocol = AttendanceService.shared
    ) {
        self.path = path
        self.bannerRepository = bannerRepository
        self.attendanceService = attendanceService
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let webViewDidFinishLoad: AnyPublisher<Void, Never>
        let attendanceButtonClicked: AnyPublisher<Void, Never>
        let attendanceCompleted: AnyPublisher<String, Never>
    }

    struct Output {
        let urlRequest: AnyPublisher<URLRequest, Never>
        let executeJavaScript: AnyPublisher<String, Never>
        let showSuccessAlert: AnyPublisher<String, Never>
        let showDuplicateAlert: AnyPublisher<String, Never>
        let updateButtonState: AnyPublisher<Bool, Never>
    }

    func transform(input: Input) -> Output {
        let urlRequestPublisher = input.viewDidLoad
            .compactMap { [weak self] _ -> URLRequest? in
                guard let self = self else { return nil }
                return WebViewManager.shared.createURLRequest(for: self.path)
            }
            .eraseToAnyPublisher()

        let updateButtonStatePublisher = input.webViewDidFinishLoad
            .map { [weak self] _ -> Bool in
                guard let self = self else { return true }
                let status = self.attendanceService.getAttendanceStatus()
                return status.isCheckedInToday
            }
            .eraseToAnyPublisher()

        let duplicateAlertSubject = PassthroughSubject<String, Never>()

        let executeJSPublisher = input.attendanceButtonClicked
            .compactMap { [weak self] _ -> String? in
                guard let self = self else { return nil }

                let status = self.attendanceService.getAttendanceStatus()
                if status.isCheckedInToday {
                    duplicateAlertSubject.send("이미 오늘 출석하였습니다.")
                    return nil
                }

                let token = self.bannerRepository.getAccessToken() ?? ""
                return "requestAttendance('\(token)')"
            }
            .eraseToAnyPublisher()

        let showSuccessAlertPublisher = input.attendanceCompleted
            .compactMap { [weak self] attendanceCount -> String? in
                guard let self = self else { return nil }

                let success = self.attendanceService.checkIn()
                guard success else {
                    duplicateAlertSubject.send("이미 오늘 출석하였습니다.")
                    return nil
                }

                return "출석 완료! 현재 출석 횟수: \(attendanceCount)회"
            }
            .eraseToAnyPublisher()

        return Output(
            urlRequest: urlRequestPublisher,
            executeJavaScript: executeJSPublisher,
            showSuccessAlert: showSuccessAlertPublisher,
            showDuplicateAlert: duplicateAlertSubject.eraseToAnyPublisher(),
            updateButtonState: updateButtonStatePublisher
        )
    }
}
