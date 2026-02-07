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
    @State private var quickFilter: QuickFilter = .today

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                filterBar
                summaryRow
                if filteredOrders.isEmpty {
                    emptyState
                } else {
                    chartsSection
                    insightsSection
                }
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(uiColor: AppColor.gray15))
        .sheet(isPresented: $isDatePickerPresented) {
            AdminSalesDatePickerView(startDate: $startDate, endDate: $endDate)
        }
        .onChange(of: quickFilter) { newValue in
            applyQuickFilter(newValue)
        }
    }

    private var filterBar: some View {
        HStack(spacing: Layout.cardSpacing) {
            Picker("기간", selection: $quickFilter) {
                ForEach(QuickFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)

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
    }

    private var summaryRow: some View {
        HStack(spacing: Layout.cardSpacing) {
            summaryCard(title: "총 매출", value: "\(summary.totalRevenue.formattedWithSeparator)원", delta: summaryDelta.totalRevenue)
            summaryCard(title: "주문 건수", value: "\(summary.orderCount)", delta: summaryDelta.orderCount)
            summaryCard(title: "평균 객단가", value: "\(summary.averageOrderValue.formattedWithSeparator)원", delta: summaryDelta.averageOrderValue)
            summaryCard(title: "평균 별점", value: summary.averageRatingText, delta: summaryDelta.averageRating)
        }
    }

    private var emptyState: some View {
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
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            chartCard(title: "시간대별 매출 추이") {
                Chart {
                    ForEach(hourlySales, id: \.self) { point in
                        BarMark(
                            x: .value("시간", point.label),
                            y: .value("매출", point.value)
                        )
                        .foregroundStyle(point.isPeak ? Color(uiColor: AppColor.brightForsythia) : Color(uiColor: AppColor.deepSprout))
                        .cornerRadius(6)
                    }

                    ForEach(hourlySales, id: \.self) { point in
                        LineMark(
                            x: .value("시간", point.label),
                            y: .value("누적", point.value)
                        )
                        .foregroundStyle(Color(uiColor: AppColor.blackSprout))
                        .lineStyle(.init(lineWidth: 2))
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
                .frame(height: Layout.chartHeight)
            }

            HStack(spacing: Layout.cardSpacing) {
                chartCard(title: "메뉴 카테고리별 비중") {
                    HStack(spacing: 16) {
                        categoryChartView()

                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                                .padding(.bottom, 4)
                            ForEach(categoryShare, id: \.self) { point in
                                HStack {
                                    Circle()
                                        .fill(colorForCategory(point.label))
                                        .frame(width: 8, height: 8)
                                    Text(point.label)
                                        .font(Font(AppFont.body3))
                                        .foregroundStyle(Color(uiColor: AppColor.gray90))
                                    Spacer()
                                    Text(percentText(for: point))
                                        .font(Font(AppFont.body3))
                                        .foregroundStyle(Color(uiColor: AppColor.gray75))
                                }
                            }
                        }
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
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Layout.listSpacing) {
            Text("운영 인사이트")
                .font(Font(AppFont.body1Bold))
                .foregroundStyle(Color(uiColor: AppColor.gray90))

            insightRow(title: "피크 타임", value: peakHourText)
            insightRow(title: "인기 카테고리", value: topCategoryText)
            insightRow(title: "평균 주문 수량", value: averageMenuCountText)
            insightRow(title: "주문 밀도", value: orderDensityText)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: AppColor.gray0))
        .cornerRadius(Layout.cardCornerRadius)
    }

    @ViewBuilder
    private func summaryCard(title: String, value: String, delta: AdminSalesDelta?) -> some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            Text(title)
                .font(Font(AppFont.caption1))
                .foregroundStyle(Color(uiColor: AppColor.gray75))
            Text(value)
                .font(Font(AppFont.title1))
                .foregroundStyle(Color(uiColor: AppColor.gray90))
            if let delta {
                Text(delta.text)
                    .font(Font(AppFont.caption1))
                    .foregroundStyle(Color(uiColor: delta.color))
            }
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

    private func insightRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Font(AppFont.body2))
                .foregroundStyle(Color(uiColor: AppColor.gray75))
            Spacer()
            Text(value)
                .font(Font(AppFont.body2Bold))
                .foregroundStyle(Color(uiColor: AppColor.gray90))
        }
        .padding(.vertical, 6)
        .overlay(
            Divider(),
            alignment: .bottom
        )
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

    private var summaryDelta: AdminSalesSummaryDelta {
        let previousOrders = previousPeriodOrders
        let totalRevenue = previousOrders.reduce(0) { $0 + $1.totalPrice }
        let orderCount = previousOrders.count
        let averageOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0
        let ratings = previousOrders.compactMap { $0.review?.rating }
        let averageRating = ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
        let previousSummary = AdminSalesSummaryModel(
            totalRevenue: totalRevenue,
            orderCount: orderCount,
            averageOrderValue: averageOrderValue,
            averageRating: averageRating
        )
        return AdminSalesSummaryDelta(current: summary, previous: previousSummary)
    }

    private var hourlySales: [AdminSalesPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredOrders) { order -> Int in
            let date = order.createdAt ?? Date()
            return calendar.component(.hour, from: date)
        }
        let points = grouped.keys.sorted().map { hour in
            let total = grouped[hour]?.reduce(0, { $0 + $1.totalPrice }) ?? 0
            return AdminSalesPoint(label: "\(hour)시", value: Double(total))
        }
        guard let maxValue = points.map(\.value).max() else { return points }
        return points.map { point in
            AdminSalesPoint(label: point.label, value: point.value, isPeak: point.value == maxValue)
        }
    }

    private var cumulativeSales: [AdminSalesPoint] {
        var runningTotal: Double = 0
        return hourlySales.map { point in
            runningTotal += point.value
            return AdminSalesPoint(label: point.label, value: runningTotal)
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

    private var categoryDonutSlices: [AdminSalesDonutSlice] {
        let points = categoryShare
        guard points.count > 1 else {
            return points.map { AdminSalesDonutSlice(label: $0.label, value: $0.value, isSeparator: false) }
        }

        let total = max(points.reduce(0) { $0 + $1.value }, 1)
        let separatorValue = max(total * 0.006, 0.2)

        var slices: [AdminSalesDonutSlice] = []
        for (index, point) in points.enumerated() {
            slices.append(AdminSalesDonutSlice(label: point.label, value: point.value, isSeparator: false))
            if index < points.count - 1 {
                slices.append(AdminSalesDonutSlice(label: "sep-\(index)", value: separatorValue, isSeparator: true))
            }
        }
        slices.append(AdminSalesDonutSlice(label: "sep-end", value: separatorValue, isSeparator: true))
        return slices
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

    private func percentText(for point: AdminSalesPoint) -> String {
        let total = max(categoryShare.reduce(0) { $0 + $1.value }, 1)
        let percent = (point.value / total) * 100
        return String(format: "%.1f%%", percent)
    }

    @ViewBuilder
    private func categoryChartView() -> some View {
        if #available(iOS 17.0, *) {
            categoryChart17()
        } else {
            categoryChart16()
        }
    }

    @available(iOS 17.0, *)
    private func categoryChart17() -> some View {
        Chart(categoryDonutSlices) { slice in
            SectorMark(
                angle: .value("비중", slice.value),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(slice.isSeparator ? Color.white : colorForCategory(slice.label))
        }
        .frame(width: Layout.chartHeight, height: Layout.chartHeight)
    }

    private func categoryChart16() -> some View {
        Chart(categoryDonutSlices) { slice in
            BarMark(
                x: .value("카테고리", slice.label),
                y: .value("비중", slice.value)
            )
            .foregroundStyle(slice.isSeparator ? Color.white : colorForCategory(slice.label))
        }
        .frame(width: Layout.chartHeight, height: Layout.chartHeight)
    }

    private func colorForCategory(_ label: String) -> Color {
        let color: UIColor
        switch label {
        case "커피":
            color = AppColor.deepSprout
        case "디저트":
            color = AppColor.brightSprout
        case "티":
            color = AppColor.blackSprout
        case "베이커리":
            color = AppColor.brightSprout2
        default:
            color = AppColor.deepSprout
        }
        return Color(uiColor: color)
    }

    private var previousPeriodOrders: [OrderListItemEntity] {
        guard let previousRange = previousDateRange else { return [] }
        return orders.filter { order in
            guard let createdAt = order.createdAt else { return false }
            return createdAt >= previousRange.start && createdAt < previousRange.end
        }
    }

    private var previousDateRange: (start: Date, end: Date)? {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        let interval = end.timeIntervalSince(start)
        guard interval > 0 else { return nil }
        let previousEnd = start
        let previousStart = previousEnd.addingTimeInterval(-interval)
        return (previousStart, previousEnd)
    }

    private func applyQuickFilter(_ filter: QuickFilter) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch filter {
        case .today:
            startDate = today
            endDate = today
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            startDate = yesterday
            endDate = yesterday
        case .thisWeek:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            startDate = weekStart
            endDate = today
        case .thisMonth:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            startDate = monthStart
            endDate = today
        }
    }

    private var peakHourText: String {
        guard let peak = hourlySales.max(by: { $0.value < $1.value }) else { return "—" }
        return "\(peak.label) (최고 매출)"
    }

    private var topCategoryText: String {
        guard let top = categoryShare.first else { return "—" }
        return top.label
    }

    private var averageMenuCountText: String {
        guard !filteredOrders.isEmpty else { return "—" }
        let totalCount = filteredOrders.reduce(0) { partial, order in
            partial + order.orderMenuList.reduce(0) { $0 + $1.quantity }
        }
        let avg = Double(totalCount) / Double(filteredOrders.count)
        return String(format: "%.1f개", avg)
    }

    private var orderDensityText: String {
        guard let previous = previousDateRange else { return "—" }
        let hours = max(previous.end.timeIntervalSince(previous.start) / 3600, 1)
        let density = Double(filteredOrders.count) / hours
        return String(format: "%.1f건/시간", density)
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

private struct AdminSalesSummaryDelta {
    let totalRevenue: AdminSalesDelta?
    let orderCount: AdminSalesDelta?
    let averageOrderValue: AdminSalesDelta?
    let averageRating: AdminSalesDelta?

    init(current: AdminSalesSummaryModel, previous: AdminSalesSummaryModel) {
        totalRevenue = AdminSalesDelta(current: Double(current.totalRevenue), previous: Double(previous.totalRevenue))
        orderCount = AdminSalesDelta(current: Double(current.orderCount), previous: Double(previous.orderCount))
        averageOrderValue = AdminSalesDelta(current: Double(current.averageOrderValue), previous: Double(previous.averageOrderValue))
        if let currentRating = current.averageRating, let previousRating = previous.averageRating {
            averageRating = AdminSalesDelta(current: currentRating, previous: previousRating, unit: "")
        } else {
            averageRating = nil
        }
    }
}

private struct AdminSalesDelta {
    let value: Double
    let unit: String

    init?(current: Double, previous: Double, unit: String = "%") {
        guard previous > 0 else { return nil }
        self.value = ((current - previous) / previous) * 100
        self.unit = unit
    }

    var text: String {
        let sign = value >= 0 ? "▲" : "▼"
        let absValue = abs(value)
        return "\(sign) \(String(format: "%.1f", absValue))\(unit)"
    }

    var color: UIColor {
        value >= 0 ? .systemRed : .systemBlue
    }
}

private enum QuickFilter: CaseIterable {
    case today
    case yesterday
    case thisWeek
    case thisMonth

    var title: String {
        switch self {
        case .today: return "오늘"
        case .yesterday: return "어제"
        case .thisWeek: return "이번 주"
        case .thisMonth: return "이번 달"
        }
    }
}

private struct AdminSalesDonutSlice: Identifiable, Hashable {
    let id: String
    let label: String
    let value: Double
    let isSeparator: Bool

    init(label: String, value: Double, isSeparator: Bool) {
        self.id = UUID().uuidString
        self.label = label
        self.value = value
        self.isSeparator = isSeparator
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
