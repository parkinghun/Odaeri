//
//  NavigationRouteStep.swift
//  Odaeri_User
//
//  Created by 박성훈 on 02/01/26.
//

import CoreLocation

struct NavigationRouteStep: Hashable, Equatable {
    let id: String
    let instruction: String
    let distanceText: String
    let coordinate: CLLocationCoordinate2D
    let direction: NavigationTurnDirection

    static func == (lhs: NavigationRouteStep, rhs: NavigationRouteStep) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
