//
//  LocationManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation
import CoreLocation
import Combine

/// GPS 위치 수신 및 위치 권한
final class LocationManager: NSObject, LocationManaging {
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    /// 현재 위치 업데이트를 방출하는 Subject
    let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    
    /// 위치 권한 상태 변경을 방출하는 Subject
    let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    
    /// 위치 에러를 방출하는 Subject
    let locationErrorSubject = PassthroughSubject<LocationError, Never>()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 업데이트
        
        // 초기 권한 상태 설정
        if #available(iOS 14.0, *) {
            authorizationStatusSubject.send(locationManager.authorizationStatus)
        } else {
            authorizationStatusSubject.send(CLLocationManager.authorizationStatus())
        }
    }
    
    // MARK: - Public Methods
    
    /// 위치 권한 체크 및 요청
    /// - 시스템 위치 서비스가 비활성화되어 있으면 에러 방출
    /// - 권한이 notDetermined이면 권한 요청
    /// - 권한이 허용되어 있으면 위치 업데이트 시작
    func checkPermissionAndStartUpdating() {
        Deferred {
            Future<Bool, Never> { promise in
                let isEnabled = CLLocationManager.locationServicesEnabled()
                promise(.success(isEnabled))
            }
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEnabled in
            guard let self else { return }
            
            guard isEnabled else {
                self.locationErrorSubject.send(.locationServicesDisabled)
                return
            }
            
            self.handleAuthorizationStatus()
        }
        .store(in: &cancellables)
    }
    
    private func handleAuthorizationStatus() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:  // 권한이 결정되지 않았으면 권한 요청
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:  // 권한이 허용되어 있으면 위치 업데이트 시작
            startUpdatingLocation()
            
        case .denied:  // 권한이 거부되었으면 에러 방출
            locationErrorSubject.send(.permissionDenied)
            
        case .restricted: // 권한이 제한되어 있으면 에러 방출 (자녀 보호 기능 등)
            locationErrorSubject.send(.permissionRestricted)
            
        @unknown default:
            locationErrorSubject.send(.unknown)
        }
    }
    
    /// 위치 업데이트 시작
    func startUpdatingLocation() {
        Deferred {
            Future<Bool, Never> { promise in
                let isEnabled = CLLocationManager.locationServicesEnabled()
                promise(.success(isEnabled))
            }
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEnabled in
            guard let self else { return }
            
            if isEnabled {  // 서비스가 켜져있으면 업데이트 시작
                self.locationManager.startUpdatingLocation()
            } else {  // 꺼져있으면 에러 방출
                self.locationErrorSubject.send(.locationServicesDisabled)
            }
        }
        .store(in: &cancellables)
        
    }
    
    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 현재 위치 한 번만 요청
    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationErrorSubject.send(.locationServicesDisabled)
            return
        }
        
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    /// iOS 14+ 권한 상태 변경 콜백
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        // 권한 상태 Subject 업데이트
        authorizationStatusSubject.send(status)
        
        // 권한 상태별 처리
        switch status {
        case .notDetermined:  // 아직 결정되지 않음 - 아무 작업도 하지 않음
            break
            
        case .authorizedWhenInUse, .authorizedAlways:  // 권한 허용됨 - 위치 업데이트 시작
            startUpdatingLocation()
            
        case .denied:  // 권한 거부됨 - 에러 방출
            locationErrorSubject.send(.permissionDenied)
            stopUpdatingLocation()
            
        case .restricted:  // 권한 제한됨 - 에러 방출
            locationErrorSubject.send(.permissionRestricted)
            stopUpdatingLocation()
            
        @unknown default:
            locationErrorSubject.send(.unknown)
            stopUpdatingLocation()
        }
    }
    
    /// iOS 13 이하 권한 상태 변경 콜백
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // iOS 14+에서는 locationManagerDidChangeAuthorization이 호출되므로 무시
        if #available(iOS 14.0, *) {
            return
        }
        
        // iOS 13 이하에서는 이 메서드 사용
        authorizationStatusSubject.send(status)
        
        switch status {
        case .notDetermined:
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
            
        case .denied:
            locationErrorSubject.send(.permissionDenied)
            stopUpdatingLocation()
            
        case .restricted:
            locationErrorSubject.send(.permissionRestricted)
            stopUpdatingLocation()
            
        @unknown default:
            locationErrorSubject.send(.unknown)
            stopUpdatingLocation()
        }
    }
    
    /// 위치 업데이트 성공 콜백
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 위치 정확도 체크 (정확도가 너무 낮으면 무시)
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 100 else {
            return
        }
        
        // 위치 업데이트 방출
        locationSubject.send(location)
    }
    
    /// 위치 업데이트 실패 콜백
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationErrorSubject.send(.permissionDenied)
                
            case .locationUnknown:
                locationErrorSubject.send(.locationUnknown)
                
            case .network:
                locationErrorSubject.send(.networkError)
                
            default:
                locationErrorSubject.send(.unknown)
            }
        } else {
            locationErrorSubject.send(.unknown)
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case locationServicesDisabled
    case permissionDenied
    case permissionRestricted
    case locationUnknown
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요."
            
        case .permissionDenied:
            return "위치 권한이 거부되었습니다. 설정에서 위치 권한을 허용해주세요."
            
        case .permissionRestricted:
            return "위치 권한이 제한되어 있습니다."
            
        case .locationUnknown:
            return "현재 위치를 확인할 수 없습니다."
            
        case .networkError:
            return "네트워크 오류가 발생했습니다."
            
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
