//
//  PaymentService.swift
//  Odaeri
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import Combine
import WebKit
import iamport_ios

enum PaymentError: LocalizedError {
    case cancelled
    case failed(message: String)
    case validationFailed(NetworkError)
    case invalidResponse
    case amountMismatch
    case duplicateReceipt
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "결제가 취소되었습니다."
        case .failed(let message):
            return message
        case .validationFailed(let networkError):
            return "영수증 검증 실패: \(networkError.localizedDescription)"
        case .invalidResponse:
            return "결제 응답이 올바르지 않습니다."
        case .amountMismatch:
            return "결제 금액이 일치하지 않습니다."
        case .duplicateReceipt:
            return "이미 처리된 결제입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

struct PaymentRequest {
    let merchantUid: String
    let amount: String
    let productName: String
    let buyerName: String

    init(storeId: String, amount: Int, storeName: String, buyerName: String = "박성훈") {
        self.merchantUid = "ios_\(storeId)_\(Int(Date().timeIntervalSince1970*1000))"
        self.amount = "\(amount)"
        self.productName = "Odaeri - \(storeName)"
        self.buyerName = buyerName
    }
}

final class PaymentService {
    private let paymentRepository: PaymentRepository
    private let iamport: Iamport
    
    init(paymentRepository: PaymentRepository = PaymentRepositoryImpl(),
         iamport: Iamport = Iamport.shared) {
        self.paymentRepository = paymentRepository
        self.iamport = iamport
    }
    
    
    private enum PaymentConfig {
        static let pgId = "INIpayTest"
        static let appScheme = "portone"
    }
    
    private lazy var userCode: String = {
        Bundle.main.value(for: .iamportUserCode)
    }()
    
    func createPayment(from request: PaymentRequest) -> IamportPayment {
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: PaymentConfig.pgId),
            merchant_uid: request.merchantUid,
            amount: request.amount
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = request.productName
            $0.buyer_name = request.buyerName
            $0.app_scheme = PaymentConfig.appScheme
        }
        
        return payment
    }
    
    func requestPayment(
        webView: WKWebView,
        request: PaymentRequest
    ) -> AnyPublisher<IamportResponse?, Never> {
        Future<IamportResponse?, Never> { [weak self] promise in
            guard let self else {
                promise(.success(nil))
                return
            }
            
            let payment = self.createPayment(from: request)
            
            iamport.paymentWebView(
                webViewMode: webView,
                userCode: self.userCode,
                payment: payment
            ) { iamportResponse in
                print("========== IAMPORT RESPONSE ==========")
                print("Success: \(iamportResponse?.success ?? false)")
                print("IMP UID: \(iamportResponse?.imp_uid ?? "nil")")
                print("Merchant UID: \(iamportResponse?.merchant_uid ?? "nil")")
                print("Error Code: \(iamportResponse?.error_code ?? "nil")")
                print("Error Message: \(iamportResponse?.error_msg ?? "nil")")
                print("======================================")
                
                promise(.success(iamportResponse))
                
                
            }
        }
        .eraseToAnyPublisher()
    }
    
    func validateReceipt(impUID: String) -> AnyPublisher<PaymentValidationEntity, NetworkError> {
        paymentRepository.validateReceipt(impUID: impUID)
    }
    
    func fetchReceipt(orderCode: String) -> AnyPublisher<PaymentReceiptEntity, NetworkError> {
        paymentRepository.fetchReceipt(orderCode: orderCode)
    }
}
