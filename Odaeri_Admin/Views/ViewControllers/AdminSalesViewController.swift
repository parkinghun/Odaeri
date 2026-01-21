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
    private var summary = AdminSalesSummary(
        todayRevenue: 0,
        averageOrderValue: 0,
        cancelRate: 0,
        insight: ""
    )
    private var charts = AdminSalesCharts(hourlySales: [], topMenus: [], weeklyTrend: [])
    private var hostingController: UIHostingController<AdminSalesDashboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray15
        render()
    }

    func updateSummary(_ summary: AdminSalesSummary) {
        self.summary = summary
        render()
    }

    func updateCharts(_ charts: AdminSalesCharts) {
        self.charts = charts
        render()
    }

    private func render() {
        let dashboardView = AdminSalesDashboardView(summary: summary, charts: charts)
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
    let summary: AdminSalesSummary
    let charts: AdminSalesCharts

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                HStack(spacing: Layout.cardSpacing) {
                    summaryCard(title: "오늘 매출", value: "\(summary.todayRevenue.formattedWithSeparator)원")
                    summaryCard(title: "평균 객단가", value: "\(summary.averageOrderValue.formattedWithSeparator)원")
                    summaryCard(title: "취소율", value: "\(summary.cancelRate)%")
                }

                chartCard(title: "시간대별 매출") {
                    Chart(charts.hourlySales, id: \.self) { point in
                        BarMark(
                            x: .value("시간", point.label),
                            y: .value("매출", point.value)
                        )
                        .foregroundStyle(Color(uiColor: AppColor.deepSprout))
                    }
                    .frame(height: Layout.chartHeight)
                }

                HStack(spacing: Layout.cardSpacing) {
                    chartCard(title: "인기 메뉴 TOP 5") {
                        Chart(charts.topMenus, id: \.self) { point in
                            BarMark(
                                x: .value("메뉴", point.label),
                                y: .value("판매", point.value)
                            )
                            .foregroundStyle(Color(uiColor: AppColor.blackSprout))
                        }
                        .frame(height: Layout.chartHeight)
                    }

                    chartCard(title: "요일별 추이") {
                        Chart(charts.weeklyTrend, id: \.self) { point in
                            LineMark(
                                x: .value("요일", point.label),
                                y: .value("매출", point.value)
                            )
                            .foregroundStyle(Color(uiColor: AppColor.deepSprout))
                            PointMark(
                                x: .value("요일", point.label),
                                y: .value("매출", point.value)
                            )
                            .foregroundStyle(Color(uiColor: AppColor.brightForsythia))
                        }
                        .frame(height: Layout.chartHeight)
                    }
                }

                Text(summary.insight)
                    .font(Font(AppFont.body1Bold))
                    .foregroundStyle(Color(uiColor: AppColor.gray90))
                    .padding(.vertical, Layout.insightVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: AppColor.gray0))
                    .cornerRadius(Layout.cardCornerRadius)
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(uiColor: AppColor.gray15))
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
}

private enum Layout {
    static let chartHeight: CGFloat = 220
    static let insightVerticalPadding: CGFloat = 12
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 8
    static let textSpacingLarge: CGFloat = 12
}
