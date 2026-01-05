//
//  EventWebViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/4/26.
//

import UIKit
import WebKit
import Combine
import SnapKit

final class EventWebViewController: BaseViewController<EventWebViewModel> {
    // MARK: - Properties
    private var webView: WKWebView!

    /// 웹에서 출석 버튼 클릭 메시지를 전달하기 위한 Subject
    private let attendanceButtonClickedSubject = PassthroughSubject<Void, Never>()

    /// 웹에서 출석 완료 메시지 및 출석 횟수를 전달하기 위한 Subject
    private let attendanceCompletedSubject = PassthroughSubject<String, Never>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }

    deinit {
        // 메모리 누수 방지: WKUserContentController에서 메시지 핸들러 제거
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "click_attendance_button")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "complete_attendance")
    }

    // MARK: - Setup

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0
    }

    private func setupWebView() {
        // WKWebView Configuration 생성
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // WeakScriptMessageHandler를 사용하여 메모리 누수 방지
        // click_attendance_button: 출석하기 버튼 클릭 시 웹에서 앱으로 전달하는 메세지
        let weakHandler = WeakScriptMessageHandler(delegate: self)
        userContentController.add(weakHandler, name: "click_attendance_button")
        // complete_attendance: 출석 완료 시 웹에서 앱으로 전달하는 메세지 (message.body에 출석 횟수 포함)
        userContentController.add(weakHandler, name: "complete_attendance")

        configuration.userContentController = userContentController

        // WKWebView 생성
        webView = WKWebView(frame: .zero, configuration: configuration)
        view.addSubview(webView)

        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Bind
    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        let input = EventWebViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            attendanceButtonClicked: attendanceButtonClickedSubject.eraseToAnyPublisher(),
            attendanceCompleted: attendanceCompletedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        // 1. URL Request 로드
        output.urlRequest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlRequest in
                self?.webView.load(urlRequest)
            }
            .store(in: &cancellables)

        // 2. JavaScript 실행 (출석 요청)
        output.executeJavaScript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] jsCode in
                self?.webView.evaluateJavaScript(jsCode, completionHandler: nil)
            }
            .store(in: &cancellables)

        // 3. 출석 완료 알럿 표시
        output.showAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "출석 완료", message: message)
            }
            .store(in: &cancellables)

        // viewDidLoad 이벤트 발생
        viewDidLoadSubject.send()
    }
}

// MARK: - WKScriptMessageHandler

extension EventWebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // 메시지 핸들러 이름으로 분기 처리
        switch message.name {
        case "click_attendance_button":
            // 웹에서 출석 버튼 클릭 시 호출됨
            // ViewModel로 이벤트 전달 → ViewModel이 JavaScript 실행 문자열 방출
            attendanceButtonClickedSubject.send()

        case "complete_attendance":
            // 웹에서 출석 완료 시 호출됨
            // message.body에 출석 횟수가 포함되어 있음 (예: 2)
            if let attendanceCount = message.body as? Int {
                attendanceCompletedSubject.send("\(attendanceCount)")
            } else if let attendanceCount = message.body as? String {
                attendanceCompletedSubject.send(attendanceCount)
            }

        default:
            break
        }
    }
}
