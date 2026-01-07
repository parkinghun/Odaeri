//
//  PaymentViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation
import Combine
import WebKit

final class PaymentViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: PaymentCoordinator?

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
    }

    private let paymentRequest: PaymentRequest
    private let paymentService: PaymentService
    private let retrySubject = PassthroughSubject<Void, Never>()

    let webView: WKWebView

    init(
        paymentRequest: PaymentRequest,
        paymentService: PaymentService
    ) {
        self.paymentRequest = paymentRequest
        self.paymentService = paymentService
        self.webView = WKWebView()
        self.webView.backgroundColor = .clear
    }

    func transform(input: Input) -> Output {
        let paymentTrigger = Publishers.Merge(
            input.viewDidLoad,
            retrySubject.eraseToAnyPublisher()
        )

        paymentTrigger
            .flatMap { [weak self] _ -> AnyPublisher<Result<PaymentValidationEntity, PaymentError>, Never> in
                guard let self = self else {
                    return Just(.failure(.unknown)).eraseToAnyPublisher()
                }

                return self.paymentService.processPaymentFlow(
                    webView: self.webView,
                    request: self.paymentRequest
                )
                .map { Result.success($0) }
                .catch { error -> AnyPublisher<Result<PaymentValidationEntity, PaymentError>, Never> in
                    return Just(.failure(error)).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let validationEntity):
                    let orderCode = validationEntity.orderItem.orderCode
                    self.coordinator?.showPaymentSuccess(orderCode: orderCode)

                case .failure(let error):
                    switch error {
                    case .validationFailed:
                        self.coordinator?.showRetryAlert(error: error) { [weak self] in
                            self?.retrySubject.send()
                        }
                    default:
                        self.coordinator?.showPaymentFailure(error: error)
                    }
                }
            }
            .store(in: &cancellables)

        return Output()
    }
}
