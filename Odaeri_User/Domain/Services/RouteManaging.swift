//
//  RouteManaging.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation
import CoreLocation
import MapKit

protocol RouteManaging: AnyObject {
    func calculateWalkingRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double
    func calculateEstimatedSteps(distanceInKm: Double) -> Int
    func calculateEstimatedTime(distanceInKm: Double) -> TimeInterval
    func formatTime(_ seconds: TimeInterval) -> String
}
