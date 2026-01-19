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
                    HStack(spacing: 8) {
                        Image(systemName: context.state.status.iconName)
                            .foregroundColor(.blackSprout)
                        Text(context.attributes.storeName)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expectedTime)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 12) {
                        StepProgressBar(currentStep: context.state.status.stepNumber)
                            .padding(.horizontal, 16)

                        if context.state.status == .readyForPickup {
                            VStack(spacing: 4) {
                                Text("주문 번호")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)

                                Text(context.attributes.orderNumber)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blackSprout)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.brightSprout)
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "storefront.fill")
                            .foregroundColor(.gray)
                        Text(context.state.status.description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(.blackSprout)
            } compactTrailing: {
                Text(context.state.expectedTime)
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
        storeName: "맛있는 치킨집",
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
