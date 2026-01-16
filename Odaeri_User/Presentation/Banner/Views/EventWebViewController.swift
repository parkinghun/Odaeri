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
    private var webView: WKWebView!
    
    private let webViewDidFinishLoadSubject = PassthroughSubject<Void, Never>()
    private let attendanceButtonClickedSubject = PassthroughSubject<Void, Never>()
    private let attendanceCompletedSubject = PassthroughSubject<String, Never>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "click_attendance_button")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "complete_attendance")
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        let weakHandler = WeakScriptMessageHandler(delegate: self)
        userContentController.add(weakHandler, name: "click_attendance_button")
        userContentController.add(weakHandler, name: "complete_attendance")

        configuration.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
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
            webViewDidFinishLoad: webViewDidFinishLoadSubject.eraseToAnyPublisher(),
            attendanceButtonClicked: attendanceButtonClickedSubject.eraseToAnyPublisher(),
            attendanceCompleted: attendanceCompletedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.urlRequest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlRequest in
                self?.webView.load(urlRequest)
            }
            .store(in: &cancellables)

        output.updateButtonState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCheckedIn in
                self?.updateAttendanceButtonState(isCheckedIn: isCheckedIn)
            }
            .store(in: &cancellables)

        output.executeJavaScript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] jsCode in
                self?.webView.evaluateJavaScript(jsCode, completionHandler: nil)
            }
            .store(in: &cancellables)

        output.showSuccessAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "출석 완료", message: message)
            }
            .store(in: &cancellables)

        output.showDuplicateAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "알림", message: message)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send()
    }

    private func updateAttendanceButtonState(isCheckedIn: Bool) {
        guard isCheckedIn else { return }

        let jsCode = """
        (function() {
            var button = document.getElementById('attendance-btn');
            if (button) {
                button.disabled = true;
                button.style.opacity = '0.5';
                button.style.cursor = 'not-allowed';
                button.innerText = '출석 완료';
            }
        })();
        """

        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
}

extension EventWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewDidFinishLoadSubject.send()
    }
}

extension EventWebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "click_attendance_button":
            attendanceButtonClickedSubject.send()

        case "complete_attendance":
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
