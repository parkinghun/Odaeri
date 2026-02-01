//
//  NavigationTurnInfo.swift
//  Odaeri_User
//
//  Created by 박성훈 on 02/01/26.
//

import Foundation

enum NavigationTurnDirection: String {
    case straight
    case left
    case right
    case uTurn

    static func from(instruction: String) -> NavigationTurnDirection {
        if instruction.contains("유턴") {
            return .uTurn
        }
        if instruction.contains("좌회전") {
            return .left
        }
        if instruction.contains("우회전") {
            return .right
        }
        return .straight
    }

    var systemImageName: String {
        switch self {
        case .left:
            return "arrow.turn.up.left"
        case .right:
            return "arrow.turn.up.right"
        case .uTurn:
            return "arrow.uturn.up"
        case .straight:
            return "arrow.up"
        }
    }
}

struct NavigationTurnInfo {
    let direction: NavigationTurnDirection
    let distanceText: String
    let instructionText: String

    static let placeholder = NavigationTurnInfo(
        direction: .straight,
        distanceText: "안내 준비 중",
        instructionText: "경로 안내를 시작합니다."
    )
}
