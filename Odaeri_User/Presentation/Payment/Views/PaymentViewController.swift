//
//  PaymentViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit
import Combine
import WebKit
import SnapKit

final class PaymentViewController: BaseViewController<PaymentViewModel> {
    private lazy var wkWebView: WKWebView = {
        viewModel.webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0
        view.addSubview(wkWebView)

        wkWebView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        let input = PaymentViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()
        )

        _ = viewModel.transform(input: input)

        viewDidLoadSubject.send()
    }
}
