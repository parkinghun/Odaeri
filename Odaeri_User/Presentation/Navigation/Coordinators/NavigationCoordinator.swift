//
//  NavigationCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/7/26.
//

import UIKit
import MapKit

protocol NavigationCoordinatorDelegate: AnyObject {
    func navigationCoordinatorDidCancel(_ coordinator: NavigationCoordinator)
    func navigationCoordinatorDidArrive(_ coordinator: NavigationCoordinator, at store: StoreEntity)
}

final class NavigationCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: NavigationCoordinatorDelegate?

    private let route: MKRoute
    private let destination: StoreEntity

    init(
        navigationController: UINavigationController,
        route: MKRoute,
        destination: StoreEntity
    ) {
        self.navigationController = navigationController
        self.route = route
        self.destination = destination
    }

    func start() {
        let viewModel = NavigationViewModel(route: route, destination: destination)
        viewModel.coordinator = self
        let viewController = NavigationViewController(viewModel: viewModel)

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen
        navController.isNavigationBarHidden = true

        navigationController.present(navController, animated: true)
    }

    func navigationDidCancel() {
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.navigationCoordinatorDidCancel(self)
        }
    }

    func navigationDidArrive(at store: StoreEntity) {
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.navigationCoordinatorDidArrive(self, at: store)
        }
    }

    func requestReroute(to destination: StoreEntity) {
        guard let currentLocation = NavigationService.shared.currentLocation else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: destination.latitude,
            longitude: destination.longitude
        )))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Failed to calculate new route: \(error.localizedDescription)")
                return
            }

            guard let newRoute = response?.routes.first else {
                print("No route found")
                return
            }

            NavigationService.shared.stopNavigation()
            NavigationService.shared.startNavigation(with: newRoute)
        }
    }
}
