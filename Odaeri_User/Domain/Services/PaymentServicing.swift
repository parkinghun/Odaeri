//
//  PaymentServicing.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation
import Combine
import WebKit

protocol PaymentServicing: AnyObject {
    func processPaymentFlow(
        webView: WKWebView,
        request: PaymentRequest
    ) -> AnyPublisher<PaymentValidationEntity, PaymentError>
    func retryPendingPayments()
    func getPendingPaymentsCount() -> Int
}
