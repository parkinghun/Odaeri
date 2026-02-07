//
//  LiveActivityManager.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import ActivityKit
import UIKit

@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<OrderPickupAttributes>?

    private init() {}

    func startActivity(storeName: String, orderNumber: String, status: OrderStatusEntity) {
        print("[LiveActivity] 시작 시도...")
        print("[LiveActivity] iOS 버전: \(UIDevice.current.systemVersion)")

        let authInfo = ActivityAuthorizationInfo()
        print("[LiveActivity] areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivity] ❌ Live Activities가 비활성화되어 있습니다")
            print("[LiveActivity] 설정 > 화면 표시 및 밝기 > Live Activities 확인 필요")
            return
        }

        let attributes = OrderPickupAttributes(
            storeName: storeName,
            orderNumber: orderNumber
        )
        print("[LiveActivity] attributes 생성: storeName=\(storeName), orderNumber=\(orderNumber)")

        let contentState = OrderPickupAttributes.ContentState(
            status: status,
            expectedTime: getExpectedTime(for: status)
        )
        print("[LiveActivity] contentState 생성: status=\(status.rawValue), expectedTime=\(getExpectedTime(for: status))")

        do {
            print("[LiveActivity] Activity.request 호출 중...")
            let activity = try Activity<OrderPickupAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("[LiveActivity] ✅ 성공! Activity ID: \(activity.id)")
            print("[LiveActivity] Activity State: \(activity.activityState)")
        } catch {
            print("[LiveActivity] ❌ 실패: \(error)")
            print("[LiveActivity] 에러 상세: \(error.localizedDescription)")
            if let activityError = error as? ActivityAuthorizationError {
                print("[LiveActivity] ActivityAuthorizationError: \(activityError)")
            }
        }
    }

    func updateActivity(status: OrderStatusEntity) {
        print("[LiveActivity] 업데이트 시도: \(status.rawValue)")

        guard let activity = currentActivity else {
            print("[LiveActivity] ❌ 업데이트 실패: currentActivity가 nil입니다")
            return
        }

        print("[LiveActivity] Activity ID: \(activity.id)")
        print("[LiveActivity] Activity State: \(activity.activityState)")

        let contentState = OrderPickupAttributes.ContentState(
            status: status,
            expectedTime: getExpectedTime(for: status)
        )
        print("[LiveActivity] 새로운 상태: status=\(status.rawValue), time=\(getExpectedTime(for: status))")

        Task {
            do {
                await activity.update(
                    ActivityContent(
                        state: contentState,
                        staleDate: nil
                    )
                )
                print("[LiveActivity] ✅ 업데이트 성공: \(status.description)")
            } catch {
                print("[LiveActivity] ❌ 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }

    func endActivity() {
        guard let activity = currentActivity else {
            print("No active Live Activity to end")
            return
        }

        let finalState = OrderPickupAttributes.ContentState(
            status: .pickedUp,
            expectedTime: "픽업 완료"
        )

        Task {
            await activity.end(using: finalState, dismissalPolicy: .after(.now + 5))
            currentActivity = nil
            print("Live Activity ended")
        }
    }

    private func getExpectedTime(for status: OrderStatusEntity) -> String {
        switch status {
        case .pendingApproval:
            return "승인 대기
        case .approved:
            return "15분"
        case .inProgress:
            return "10분"
        case .readyForPickup:
            return "픽업 가능"
        case .pickedUp:
            return "픽업 완료"
        }
    }
}
