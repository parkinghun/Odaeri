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
        let toggleCameraMode: AnyPublisher<Bool, Never>
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
        let showArrivalAlert: AnyPublisher<String, Never>
        let showRerouteAlert: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let cameraSubject = PassthroughSubject<MKMapCamera?, Never>()
        let showArrivalAlertSubject = PassthroughSubject<String, Never>()
        let showRerouteAlertSubject = PassthroughSubject<Void, Never>()
        let is3DCameraMode = CurrentValueSubject<Bool, Never>(true)

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

        input.toggleCameraMode
            .sink { is3D in
                is3DCameraMode.send(is3D)
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

        Publishers.CombineLatest3(
            navigationService.$currentLocation,
            navigationService.$currentHeading,
            is3DCameraMode
        )
        .compactMap { [weak self] location, heading, is3D in
            guard is3D else { return nil }
            return self?.navigationService.createCameraForCurrentLocation(
                pitch: 60,
                heading: heading?.trueHeading,
                altitude: 500
            )
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
            showArrivalAlert: showArrivalAlertSubject.eraseToAnyPublisher(),
            showRerouteAlert: showRerouteAlertSubject.eraseToAnyPublisher()
        )
    }
}
