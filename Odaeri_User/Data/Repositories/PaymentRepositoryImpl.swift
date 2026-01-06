//
//  PaymentRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import Combine
import Moya

final class PaymentRepositoryImpl: PaymentRepository {
    private let provider = MoyaProvider<PaymentAPI>()

    func validateReceipt(impUID: String) -> AnyPublisher<PaymentValidationEntity, NetworkError> {
        provider.requestPublisher(.validateReceipt(impUID: impUID))
            .map { (response: PaymentValidationResponse) in
                PaymentValidationEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func fetchReceipt(orderCode: String) -> AnyPublisher<PaymentReceiptEntity, NetworkError> {
        provider.requestPublisher(.fetchReceipt(orderCode: orderCode))
            .map { (response: PaymentReceiptResponse) in
                PaymentReceiptEntity(from: response)
            }
            .eraseToAnyPublisher()
    }
}
