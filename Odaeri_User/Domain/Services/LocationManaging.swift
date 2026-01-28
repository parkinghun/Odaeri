//
//  LocationManaging.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation
import CoreLocation
import Combine

protocol LocationManaging: AnyObject {
    var locationSubject: CurrentValueSubject<CLLocation?, Never> { get }
    var authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never> { get }
    var locationErrorSubject: PassthroughSubject<LocationError, Never> { get }

    func checkPermissionAndStartUpdating()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()
}
