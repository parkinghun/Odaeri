//
//  AdminSalesViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import UIKit
import SwiftUI
import Charts

final class AdminSalesViewController: UIViewController {
    private var orders: [OrderListItemEntity] = []
    private var hostingController: UIHostingController<AdminSalesDashboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray15
        render()
    }

    func updateOrders(_ orders: [OrderListItemEntity]) {
        self.orders = orders
        render()
    }

    private func render() {
        let dashboardView = AdminSalesDashboardView(orders: orders)
        if let hostingController {
            hostingController.rootView = dashboardView
            hostingController.view.backgroundColor = AppColor.gray15
            return
        }

        let controller = UIHostingController(rootView: dashboardView)
        controller.view.backgroundColor = AppColor.gray15
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        controller.didMove(toParent: self)
        hostingController = controller
    }
}

struct AdminSalesDashboardView: View {
    let orders: [OrderListItemEntity]
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var endDate = Calendar.current.startOfDay(for: Date())
    @State private var isDatePickerPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                HStack {
                    Spacer()
                    Button(action: {
                        isDatePickerPresented = true
                    }) {
                        HStack(spacing: Layout.textSpacing) {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("기간 선택")
                                    .font(Font(AppFont.caption1))
                                    .foregroundStyle(Color(uiColor: AppColor.gray60))
                                Text(dateRangeText)
                                    .font(Font(AppFont.body2))
                                    .foregroundStyle(Color(uiColor: AppColor.gray90))
                            }
                        }
                        .padding(.vertical, Layout.filterVerticalPadding)
                        .padding(.horizontal, Layout.filterHorizontalPadding)
                        .background(Color(uiColor: AppColor.gray0))
                        .cornerRadius(Layout.filterCornerRadius)
                    }
                }

                HStack(spacing: Layout.cardSpacing) {
                    summaryCard(title: "총 매출", value: "\(summary.totalRevenue.formattedWithSeparator)원")
                    summaryCard(title: "주문 건수", value: "\(summary.orderCount)")
                    summaryCard(title: "평균 객단가", value: "\(summary.averageOrderValue.formattedWithSeparator)원")
                    summaryCard(title: "평균 별점", value: summary.averageRatingText)
                }

                if filteredOrders.isEmpty {
                    VStack(spacing: Layout.emptySpacing) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(uiColor: AppColor.gray60))
                        Text("선택한 기간에 매출 데이터가 없습니다.")
                            .font(Font(AppFont.body2))
                            .foregroundStyle(Color(uiColor: AppColor.gray60))
                    }
                    .frame(maxWidth: .infinity, minHeight: Layout.emptyHeight)
                    .background(Color(uiColor: AppColor.gray0))
                    .cornerRadius(Layout.cardCornerRadius)
                } else {
                    chartCard(title: "시간대별 매출 추이") {
                        Chart(hourlySales, id: \.self) { point in
                            BarMark(
                                x: .value("시간", point.label),
                                y: .value("매출", point.value)
                            )
                            .foregroundStyle(Color(uiColor: AppColor.deepSprout))
                        }
                        .frame(height: Layout.chartHeight)
                    }

                    HStack(spacing: Layout.cardSpacing) {
                        chartCard(title: "메뉴 카테고리별 비중") {
                            if #available(iOS 17.0, *) {
                                Chart(categoryShare, id: \.self) { point in
                                    SectorMark(
                                        angle: .value("비중", point.value),
                                        innerRadius: .ratio(0.6)
                                    )
                                    .foregroundStyle(by: .value("카테고리", point.label))
                                }
                                .frame(height: Layout.chartHeight)
                            } else {
                                Chart(categoryShare, id: \.self) { point in
                                    BarMark(
                                        x: .value("카테고리", point.label),
                                        y: .value("비중", point.value)
                                    )
                                    .foregroundStyle(Color(uiColor: AppColor.deepSprout))
                                }
                                .frame(height: Layout.chartHeight)
                            }
                        }

                        chartCard(title: "인기 메뉴 TOP 5") {
                            Chart(topMenus, id: \.self) { point in
                                BarMark(
                                    x: .value("판매", point.value),
                                    y: .value("메뉴", point.label)
                                )
                                .foregroundStyle(Color(uiColor: AppColor.blackSprout))
                            }
                            .frame(height: Layout.chartHeight)
                        }
                    }

                    VStack(alignment: .leading, spacing: Layout.listSpacing) {
                        Text("상세 거래 내역")
                            .font(Font(AppFont.body1Bold))
                            .foregroundStyle(Color(uiColor: AppColor.gray90))

                        ForEach(filteredOrders, id: \.orderId) { order in
                            AdminSalesOrderRowView(order: order)
                        }
                    }
                    .padding(Layout.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: AppColor.gray0))
                    .cornerRadius(Layout.cardCornerRadius)
                }
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(uiColor: AppColor.gray15))
        .sheet(isPresented: $isDatePickerPresented) {
            AdminSalesDatePickerView(startDate: $startDate, endDate: $endDate)
        }
    }

    @ViewBuilder
    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            Text(title)
                .font(Font(AppFont.caption1))
                .foregroundStyle(Color(uiColor: AppColor.gray75))
            Text(value)
                .font(Font(AppFont.title1))
                .foregroundStyle(Color(uiColor: AppColor.gray90))
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: AppColor.gray0))
        .cornerRadius(Layout.cardCornerRadius)
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Layout.textSpacingLarge) {
            Text(title)
                .font(Font(AppFont.body1Bold))
                .foregroundStyle(Color(uiColor: AppColor.gray90))
            content()
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: AppColor.gray0))
        .cornerRadius(Layout.cardCornerRadius)
    }

    private var filteredOrders: [OrderListItemEntity] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        return orders.filter { order in
            guard let createdAt = order.createdAt else { return false }
            return createdAt >= start && createdAt < end
        }
    }

    private var summary: AdminSalesSummaryModel {
        let totalRevenue = filteredOrders.reduce(0) { $0 + $1.totalPrice }
        let orderCount = filteredOrders.count
        let averageOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0
        let ratings = filteredOrders.compactMap { $0.review?.rating }
        let averageRating = ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
        return AdminSalesSummaryModel(
            totalRevenue: totalRevenue,
            orderCount: orderCount,
            averageOrderValue: averageOrderValue,
            averageRating: averageRating
        )
    }

    private var hourlySales: [AdminSalesPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredOrders) { order -> Int in
            let date = order.createdAt ?? Date()
            return calendar.component(.hour, from: date)
        }
        return grouped.keys.sorted().map { hour in
            let total = grouped[hour]?.reduce(0, { $0 + $1.totalPrice }) ?? 0
            return AdminSalesPoint(label: "\(hour)시", value: Double(total))
        }
    }

    private var categoryShare: [AdminSalesPoint] {
        var counts: [String: Int] = [:]
        filteredOrders.forEach { order in
            order.orderMenuList.forEach { menuItem in
                counts[menuItem.menu.category, default: 0] += menuItem.quantity
            }
        }
        return counts.map { AdminSalesPoint(label: $0.key, value: Double($0.value)) }
            .sorted { $0.value > $1.value }
    }

    private var topMenus: [AdminSalesPoint] {
        var counts: [String: Int] = [:]
        filteredOrders.forEach { order in
            order.orderMenuList.forEach { menuItem in
                counts[menuItem.menu.name, default: 0] += menuItem.quantity
            }
        }
        return counts.map { AdminSalesPoint(label: $0.key, value: Double($0.value)) }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0 }
    }

    private var dateRangeText: String {
        let startText = DateFormatter.dotDate.string(from: startDate)
        let endText = DateFormatter.dotDate.string(from: endDate)
        return "\(startText) - \(endText)"
    }
}

private struct AdminSalesSummaryModel {
    let totalRevenue: Int
    let orderCount: Int
    let averageOrderValue: Int
    let averageRating: Double?

    var averageRatingText: String {
        guard let averageRating else { return "—" }
        return "⭐\(String(format: "%.1f", averageRating))"
    }
}

private struct AdminSalesOrderRowView: View {
    let order: OrderListItemEntity

    var body: some View {
        HStack(spacing: Layout.rowSpacing) {
            Text(timeText)
                .font(Font(AppFont.caption1))
                .foregroundStyle(Color(uiColor: AppColor.gray60))
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: Layout.rowInnerSpacing) {
                Text(menuSummary)
                    .font(Font(AppFont.body2))
                    .foregroundStyle(Color(uiColor: AppColor.gray90))
                StatusBadgeView(status: order.currentOrderStatus)
            }

            Spacer()

            Text("\(order.totalPrice.formattedWithSeparator)원")
                .font(Font(AppFont.body2Bold))
                .foregroundStyle(Color(uiColor: AppColor.gray90))
        }
        .padding(.vertical, Layout.rowVerticalPadding)
        .overlay(
            Divider()
                .padding(.leading, 52),
            alignment: .bottom
        )
    }

    private var timeText: String {
        guard let createdAt = order.createdAt else { return "--:--" }
        return DateFormatter.timeDisplay.string(from: createdAt)
    }

    private var menuSummary: String {
        guard let first = order.orderMenuList.first?.menu.name else {
            return "메뉴 정보 없음"
        }
        let extra = max(order.orderMenuList.count - 1, 0)
        if extra > 0 {
            return "\(first) 외 \(extra)건"
        }
        return first
    }
}

private struct StatusBadgeView: View {
    let status: OrderStatusEntity

    var body: some View {
        Text(status.description)
            .font(Font(AppFont.caption2))
            .foregroundStyle(Color(uiColor: textColor))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(uiColor: backgroundColor))
            .cornerRadius(10)
    }

    private var backgroundColor: UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.gray45
        case .approved, .inProgress:
            return AppColor.deepSprout
        case .readyForPickup:
            return AppColor.blackSprout
        case .pickedUp:
            return AppColor.gray60
        }
    }

    private var textColor: UIColor {
        switch status {
        case .pendingApproval:
            return AppColor.gray90
        default:
            return AppColor.gray0
        }
    }
}

private struct AdminSalesDatePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                DatePicker("종료일", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            .padding(20)
            .navigationTitle("기간 선택")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        if endDate < startDate {
                            endDate = startDate
                        }
                        dismiss()
                    }
                }
            }
            .onChange(of: startDate) { newValue in
                if endDate < newValue {
                    endDate = newValue
                }
            }
        }
    }
}

private enum Layout {
    static let chartHeight: CGFloat = 220
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 8
    static let textSpacingLarge: CGFloat = 12
    static let listSpacing: CGFloat = 12
    static let rowSpacing: CGFloat = 12
    static let rowInnerSpacing: CGFloat = 6
    static let rowVerticalPadding: CGFloat = 12
    static let filterVerticalPadding: CGFloat = 8
    static let filterHorizontalPadding: CGFloat = 12
    static let filterCornerRadius: CGFloat = 10
    static let emptyHeight: CGFloat = 280
    static let emptySpacing: CGFloat = 12
}
