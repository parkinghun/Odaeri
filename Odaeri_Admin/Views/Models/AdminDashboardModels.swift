//
//  AdminDashboardModels.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation

enum AdminDashboardTab: Int, CaseIterable {
    case inProgress
    case completed
    case orderLookup
    case sales
    case storeManagement
}

enum AdminSortOrder: Int, CaseIterable {
    case latest
    case oldest

    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .oldest:
            return "과거순"
        }
    }
}

struct AdminSideTabBarItem: Hashable {
    let tab: AdminDashboardTab
    let title: String
    let count: Int?
    let iconName: String
}

struct AdminSalesSummary: Hashable {
    let todayRevenue: Int
    let averageOrderValue: Int
    let cancelRate: Double
    let insight: String
}

struct AdminSalesPoint: Hashable {
    let label: String
    let value: Double
}

struct AdminSalesCharts: Hashable {
    let hourlySales: [AdminSalesPoint]
    let topMenus: [AdminSalesPoint]
    let weeklyTrend: [AdminSalesPoint]
}

struct AdminOrderStatusUpdate {
    let order: OrderListItemEntity
    let nextStatus: OrderStatusEntity
}

enum AdminOrderTiming {
    static let estimatedMinutes = 20
}
