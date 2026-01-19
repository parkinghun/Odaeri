//
//  LiveActivityTestView.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import SwiftUI

@available(iOS 16.2, *)
struct LiveActivityTestView: View {
    private let manager = LiveActivityManager.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("라이브 액티비티 시작")) {
                    Button("주문 시작하기") {
                        manager.startActivity(
                            storeName: "맛있는 치킨집",
                            orderNumber: "#A-123",
                            status: .pendingApproval
                        )
                    }
                }

                Section(header: Text("상태 업데이트")) {
                    ForEach(OrderStatusEntity.allCases, id: \.self) { status in
                        Button(action: {
                            manager.updateActivity(status: status)
                        }) {
                            HStack {
                                Image(systemName: status.iconName)
                                    .foregroundColor(Color.blackSprout)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(status.description)
                                        .font(.headline)

                                    Text("Step \(status.stepNumber)/5")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Text(getExpectedTime(for: status))
                                    .font(.caption)
                                    .foregroundColor(Color.blackSprout)
                            }
                        }
                    }
                }

                Section(header: Text("라이브 액티비티 종료")) {
                    Button("종료하기", role: .destructive) {
                        manager.endActivity()
                    }
                }

                Section(header: Text("시뮬레이션")) {
                    Button("전체 프로세스 시뮬레이션") {
                        runFullSimulation()
                    }
                }
            }
            .navigationTitle("Live Activity 테스트")
        }
    }

    private func getExpectedTime(for status: OrderStatusEntity) -> String {
        switch status {
        case .pendingApproval:
            return "접수 중"
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

    private func runFullSimulation() {
        manager.startActivity(
            storeName: "맛있는 치킨집",
            orderNumber: "#A-123",
            status: .pendingApproval
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            manager.updateActivity(status: .approved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            manager.updateActivity(status: .inProgress)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            manager.updateActivity(status: .readyForPickup)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            manager.updateActivity(status: .pickedUp)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 18) {
            manager.endActivity()
        }
    }
}

@available(iOS 16.2, *)
struct LiveActivityTestView_Previews: PreviewProvider {
    static var previews: some View {
        LiveActivityTestView()
    }
}
