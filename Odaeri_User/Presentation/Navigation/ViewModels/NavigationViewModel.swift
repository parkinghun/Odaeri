//
//  NavigationViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/7/26.
//

import Foundation
import Combine
import CoreLocation
import MapKit

final class NavigationViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: NavigationCoordinator?

    private let navigationService: NavigationService
    private let route: MKRoute
    let destination: StoreEntity

    init(
        route: MKRoute,
        destination: StoreEntity,
        navigationService: NavigationService = .shared
    ) {
        self.route = route
        self.destination = destination
        self.navigationService = navigationService
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let viewDidDisappear: AnyPublisher<Void, Never>
        let cancelButtonTapped: AnyPublisher<Void, Never>
        let rerouteButtonTapped: AnyPublisher<Void, Never>
        let rerouteConfirmed: AnyPublisher<Void, Never>
        let toggleCameraMode: AnyPublisher<Bool, Never>
        let userDidDragMap: AnyPublisher<Void, Never>
        let relocateButtonTapped: AnyPublisher<Void, Never>
        let mapCameraAltitudeChanged: AnyPublisher<CLLocationDistance, Never>
    }

    struct Output {
        let currentLocation: AnyPublisher<CLLocation?, Never>
        let currentHeading: AnyPublisher<CLHeading?, Never>
        let navigationState: AnyPublisher<NavigationState, Never>
        let passedPath: AnyPublisher<[CLLocationCoordinate2D], Never>
        let remainingPath: AnyPublisher<[CLLocationCoordinate2D], Never>
        let distanceToDestination: AnyPublisher<String, Never>
        let estimatedTime: AnyPublisher<String, Never>
        let camera: AnyPublisher<MKMapCamera?, Never>
        let isTrackingUser: AnyPublisher<Bool, Never>
        let showArrivalAlert: AnyPublisher<String, Never>
        let showRerouteAlert: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let cameraSubject = PassthroughSubject<MKMapCamera?, Never>()
        let showArrivalAlertSubject = PassthroughSubject<String, Never>()
        let showRerouteAlertSubject = PassthroughSubject<Void, Never>()
        let is3DCameraMode = CurrentValueSubject<Bool, Never>(true)
        let isTrackingUserSubject = CurrentValueSubject<Bool, Never>(true)
        let isAtDefaultZoomLevel = CurrentValueSubject<Bool, Never>(true)

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.navigationService.startNavigation(with: self?.route ?? MKRoute())
            }
            .store(in: &cancellables)

        input.viewDidDisappear
            .sink { [weak self] _ in
                self?.navigationService.stopNavigation()
            }
            .store(in: &cancellables)

        input.cancelButtonTapped
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.navigationService.stopNavigation()
                self.coordinator?.navigationDidCancel()
            }
            .store(in: &cancellables)

        input.rerouteButtonTapped
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.coordinator?.requestReroute(to: self.destination)
            }
            .store(in: &cancellables)

        input.rerouteConfirmed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.coordinator?.requestReroute(to: self.destination)
            }
            .store(in: &cancellables)

        input.toggleCameraMode
            .sink { is3D in
                is3DCameraMode.send(is3D)
                isTrackingUserSubject.send(true)
            }
            .store(in: &cancellables)

        input.userDidDragMap
            .sink { _ in
                isTrackingUserSubject.send(false)
            }
            .store(in: &cancellables)

        input.relocateButtonTapped
            .sink { _ in
                isTrackingUserSubject.send(true)
                isAtDefaultZoomLevel.send(true)
            }
            .store(in: &cancellables)

        input.mapCameraAltitudeChanged
            .sink { altitude in
                let is3D = is3DCameraMode.value
                let defaultAltitude: CLLocationDistance = is3D ? 700 : 1500
                let tolerance: CLLocationDistance = 200

                let isAtDefault = abs(altitude - defaultAltitude) <= tolerance
                isAtDefaultZoomLevel.send(isAtDefault)
            }
            .store(in: &cancellables)

        navigationService.$navigationState
            .sink { [weak self] state in
                guard let self = self else { return }

                if state == .arrived {
                    showArrivalAlertSubject.send(self.destination.name)
                    self.coordinator?.navigationDidArrive(at: self.destination)
                } else if state == .offRoute {
                    showRerouteAlertSubject.send(())
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                navigationService.$currentLocation,
                navigationService.$currentHeading,
                is3DCameraMode,
                isTrackingUserSubject
            ),
            isAtDefaultZoomLevel
        )
        .compactMap { [weak self] combined, isAtDefaultZoom in
            let (location, heading, is3D, isTracking) = combined
            guard isTracking, let location = location else { return nil }

            let shouldApplyHeading = isAtDefaultZoom

            if is3D {
                return self?.navigationService.createCameraForCurrentLocation(
                    pitch: 65,
                    heading: shouldApplyHeading ? heading?.trueHeading : 0,
                    altitude: 700
                )
            } else {
                return MKMapCamera(
                    lookingAtCenter: location.coordinate,
                    fromDistance: 1500,
                    pitch: 0,
                    heading: 0
                )
            }
        }
        .sink { camera in
            cameraSubject.send(camera)
        }
        .store(in: &cancellables)

        let distanceString = navigationService.$distanceToDestination
            .map { distance -> String in
                if distance >= 1000 {
                    return String(format: "%.1fkm", distance / 1000)
                } else {
                    return String(format: "%.0fm", distance)
                }
            }
            .eraseToAnyPublisher()

        let timeString = navigationService.$estimatedTimeRemaining
            .map { seconds -> String in
                let minutes = Int(seconds / 60)
                if minutes >= 60 {
                    let hours = minutes / 60
                    let remainingMinutes = minutes % 60
                    return String(format: "%d시간 %d분", hours, remainingMinutes)
                } else {
                    return String(format: "%d분", minutes)
                }
            }
            .eraseToAnyPublisher()

        return Output(
            currentLocation: navigationService.$currentLocation.eraseToAnyPublisher(),
            currentHeading: navigationService.$currentHeading.eraseToAnyPublisher(),
            navigationState: navigationService.$navigationState.eraseToAnyPublisher(),
            passedPath: navigationService.$passedPath.eraseToAnyPublisher(),
            remainingPath: navigationService.$remainingPath.eraseToAnyPublisher(),
            distanceToDestination: distanceString,
            estimatedTime: timeString,
            camera: cameraSubject.eraseToAnyPublisher(),
            isTrackingUser: isTrackingUserSubject.eraseToAnyPublisher(),
            showArrivalAlert: showArrivalAlertSubject.eraseToAnyPublisher(),
            showRerouteAlert: showRerouteAlertSubject.eraseToAnyPublisher()
        )
    }
}
