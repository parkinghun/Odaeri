//
//  WeakScriptMessageHandler.swift
//  Odaeri
//
//  Created by 박성훈 on 1/4/26.
//

import WebKit

/// WKScriptMessageHandler의 메모리 누수를 방지하기 위한 래퍼 클래스
/// WKUserContentController가 handler를 강하게 참조하므로,
/// weak reference를 사용하여 순환 참조를 방지합니다.
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
