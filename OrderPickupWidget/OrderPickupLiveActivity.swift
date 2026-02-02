//
//  OrderPickupLiveActivity.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct OrderPickupLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderPickupAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.storeName)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.leading, 6)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expectedTime)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.trailing, 6)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        StepProgressBar(currentStep: context.state.status.stepNumber)
                            .padding(.horizontal, 6)
                            .padding(.top, 6)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(.blackSprout)
            } compactTrailing: {
                Text(context.state.status.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blackSprout)
            } minimal: {
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(.blackSprout)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<OrderPickupAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.storeName)
                        .font(.system(size: 16, weight: .bold))

                    Text(context.state.status.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.state.expectedTime)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blackSprout)

                    Text("주문번호: \(context.attributes.orderNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            StepProgressBar(currentStep: context.state.status.stepNumber)
                .padding(.top, 4)
        }
        .padding(16)
    }
}

struct OrderPickupLiveActivity_Previews: PreviewProvider {
    static let attributes = OrderPickupAttributes(
        storeName: "창동 바이닐: 쉼",
        orderNumber: "#A-123"
    )

    static let contentState = OrderPickupAttributes.ContentState(
        status: .readyForPickup,
        expectedTime: "8분"
    )

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Lock Screen")
    }
}
