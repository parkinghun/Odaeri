//
//  PendingPaymentRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import Foundation

final class PendingPaymentRepositoryImpl: PendingPaymentRepository {
    private let keychainManager: KeychainManager
    private let key = "pendingPayments"

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    func savePendingPayment(_ payment: PendingPaymentEntity) {
        var payments = getPendingPayments()

        if let index = payments.firstIndex(where: { $0.impUID == payment.impUID }) {
            payments[index] = payment
        } else {
            payments.append(payment)
        }

        savePayments(payments)
    }

    func getPendingPayments() -> [PendingPaymentEntity] {
        do {
            let payments = try keychainManager.get(for: key, type: [PendingPaymentEntity].self)
            return payments.filter { !$0.isExpired }
        } catch KeychainError.itemNotFound {
            return []
        } catch {
            print("Failed to load pending payments from keychain: \(error)")
            return []
        }
    }

    func removePendingPayment(impUID: String) {
        var payments = getPendingPayments()
        payments.removeAll { $0.impUID == impUID }
        savePayments(payments)
    }

    func updatePendingPayment(_ payment: PendingPaymentEntity) {
        savePendingPayment(payment)
    }

    func clearAllPendingPayments() {
        do {
            try keychainManager.delete(for: key)
        } catch {
            print("Failed to clear pending payments: \(error)")
        }
    }

    private func savePayments(_ payments: [PendingPaymentEntity]) {
        do {
            if payments.isEmpty {
                try keychainManager.delete(for: key)
            } else {
                try keychainManager.save(payments, for: key)
            }
        } catch {
            print("Failed to save pending payments to keychain: \(error)")
        }
    }
}
