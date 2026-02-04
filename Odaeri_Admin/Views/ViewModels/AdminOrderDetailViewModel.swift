//
//  AdminOrderDetailViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/02/26.
//

import Foundation
import Combine

final class AdminOrderDetailViewModel {
    @Published private(set) var order: OrderListItemEntity?
    @Published private(set) var estimatedMinutes: Int

    init(estimatedMinutes: Int = 15) {
        self.estimatedMinutes = estimatedMinutes
    }

    func updateOrder(_ order: OrderListItemEntity?) {
        self.order = order
    }

    func updateEstimatedMinutes(_ minutes: Int) {
        estimatedMinutes = max(0, minutes)
    }
}
