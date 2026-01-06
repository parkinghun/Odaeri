//
//  PaymentRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import Combine

protocol PaymentRepository {
    func validateReceipt(impUID: String) -> AnyPublisher<PaymentValidationEntity, NetworkError>
    func fetchReceipt(orderCode: String) -> AnyPublisher<PaymentReceiptEntity, NetworkError>
}
