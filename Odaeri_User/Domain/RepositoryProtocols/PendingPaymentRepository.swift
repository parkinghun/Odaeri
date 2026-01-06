//
//  PendingPaymentRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

protocol PendingPaymentRepository {
    func savePendingPayment(_ payment: PendingPaymentEntity)
    func getPendingPayments() -> [PendingPaymentEntity]
    func removePendingPayment(impUID: String)
    func updatePendingPayment(_ payment: PendingPaymentEntity)
    func clearAllPendingPayments()
}
