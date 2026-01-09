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
    
    init(orderCode: String, amount: Int, storeName: String, buyerName: String = "박성훈") {
        self.merchantUid = orderCode
        self.amount = "\(amount)"
        self.productName = "Odaeri - \(storeName)"
        self.buyerName = buyerName
    }
}

final class PaymentService {
    static let shared = PaymentService()

    private enum PaymentConfig {
        static let pgId = "INIpayTest"
        static let appScheme = "portone"
    }

    private let paymentRepository: PaymentRepository
    private let pendingPaymentRepository: PendingPaymentRepository
    private let iamport: Iamport
    private var retrySubscriptions = Set<AnyCancellable>()
    private lazy var userCode: String = {
        Bundle.main.value(for: .iamportUserCode)
    }()

    private init(
        paymentRepository: PaymentRepository = PaymentRepositoryImpl(),
        pendingPaymentRepository: PendingPaymentRepository = PendingPaymentRepositoryImpl(),
        iamport: Iamport = Iamport.shared
    ) {
        self.paymentRepository = paymentRepository
        self.pendingPaymentRepository = pendingPaymentRepository
        self.iamport = iamport
    }
    
    func processPaymentFlow(
        webView: WKWebView,
        request: PaymentRequest
    ) -> AnyPublisher<PaymentValidationEntity, PaymentError> {
        requestPayment(webView: webView, request: request)
            .tryMap { response -> (impUID: String, orderCode: String, amount: String, productName: String) in
                guard let response = response else {
                    throw PaymentError.invalidResponse
                }

                guard response.success == true else {
                    if let errorMsg = response.error_msg {
                        throw PaymentError.failed(message: errorMsg)
                    }
                    throw PaymentError.cancelled
                }

                guard let impUID = response.imp_uid else {
                    throw PaymentError.invalidResponse
                }

                return (impUID, request.merchantUid, request.amount, request.productName)
            }
            .flatMap { [weak self] impUID, orderCode, amount, productName -> AnyPublisher<PaymentValidationEntity, Error> in
                guard let self = self else {
                    return Fail(error: PaymentError.unknown)
                        .eraseToAnyPublisher()
                }

                let storeName = productName.replacingOccurrences(of: "Odaeri - ", with: "")
                let amountInt = Int(amount) ?? 0
                let pendingPayment = PendingPaymentEntity(
                    impUID: impUID,
                    orderCode: orderCode,
                    amount: amountInt,
                    storeName: storeName
                )
                self.pendingPaymentRepository.savePendingPayment(pendingPayment)
                print("결제 성공, 보험용 pending 저장: \(impUID)")

                return self.validateReceipt(impUID: impUID)
                    .handleEvents(receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }

                        if case .finished = completion {
                            self.pendingPaymentRepository.removePendingPayment(impUID: impUID)
                            print("영수증 검증 성공, pending 제거: \(impUID)")
                        }
                    })
                    .mapError { networkError -> Error in
                        print("영수증 검증 실패, pending 유지: \(impUID)")
                        return PaymentError.validationFailed(networkError)
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { error -> PaymentError in
                if let paymentError = error as? PaymentError {
                    return paymentError
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    private func createPayment(from request: PaymentRequest) -> IamportPayment {
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: PaymentConfig.pgId),
            merchant_uid: request.merchantUid,
            amount: request.amount
        )
        payment.pay_method = PayMethod.card.rawValue
        payment.name = request.productName
        payment.buyer_name = request.buyerName
        payment.app_scheme = PaymentConfig.appScheme

        return payment
    }
    
    private func requestPayment(
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
                promise(.success(iamportResponse))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func validateReceipt(impUID: String) -> AnyPublisher<PaymentValidationEntity, NetworkError> {
        paymentRepository.validateReceipt(impUID: impUID)
    }

    func retryPendingPayments() {
        retrySubscriptions.removeAll()

        let pendingPayments = pendingPaymentRepository.getPendingPayments()

        guard !pendingPayments.isEmpty else { return }

        print("재검증할 pending payment \(pendingPayments.count)개 발견")

        let totalCount = pendingPayments.count

        pendingPayments.forEach { pendingPayment in
            if pendingPayment.hasExceededMaxRetries {
                print("최대 재시도 횟수 초과, pending 제거: \(pendingPayment.impUID)")
                self.pendingPaymentRepository.removePendingPayment(impUID: pendingPayment.impUID)
                return
            }

            self.validateReceipt(impUID: pendingPayment.impUID)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }

                        if case .failure(let networkError) = completion {
                            if networkError.isNetworkConnectionError {
                                print("네트워크 에러로 재검증 실패, 재시도 횟수 증가: \(pendingPayment.impUID)")
                                let updatedPayment = pendingPayment.incrementRetryCount()
                                self.pendingPaymentRepository.updatePendingPayment(updatedPayment)
                            } else {
                                print("재검증 실패 (네트워크 아님), pending 제거: \(pendingPayment.impUID)")
                                self.pendingPaymentRepository.removePendingPayment(impUID: pendingPayment.impUID)
                            }
                        }
                    },
                    receiveValue: { [weak self] validationEntity in
                        guard let self = self else { return }

                        print("영수증 재검증 성공, pending 제거: \(pendingPayment.impUID)")
                        self.pendingPaymentRepository.removePendingPayment(impUID: pendingPayment.impUID)

                        let info = PendingPaymentValidatedInfo(
                            validationEntity: validationEntity,
                            storeName: pendingPayment.storeName,
                            count: totalCount
                        )

                        NotificationCenter.default.post(
                            name: .pendingPaymentValidated,
                            object: nil,
                            userInfo: ["info": info]
                        )
                    }
                )
                .store(in: &retrySubscriptions)
        }
    }

    func getPendingPaymentsCount() -> Int {
        return pendingPaymentRepository.getPendingPayments().count
    }
}
