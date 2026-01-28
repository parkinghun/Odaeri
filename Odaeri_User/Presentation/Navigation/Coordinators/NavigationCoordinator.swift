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
    private let navigationService: NavigationService
    private let routeManager: RouteManaging

    init(
        navigationController: UINavigationController,
        route: MKRoute,
        destination: StoreEntity,
        navigationService: NavigationService,
        routeManager: RouteManaging
    ) {
        self.navigationController = navigationController
        self.route = route
        self.destination = destination
        self.navigationService = navigationService
        self.routeManager = routeManager
    }

    func start() {
        let viewModel = NavigationViewModel(
            route: route,
            destination: destination,
            navigationService: navigationService
        )
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
        guard let currentLocation = navigationService.currentLocation else { return }
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let newRoute = try await self.routeManager.calculateWalkingRoute(
                    from: currentLocation.coordinate,
                    to: destinationCoordinate
                )
                self.navigationService.stopNavigation()
                self.navigationService.startNavigation(with: newRoute)
            } catch {
                print("Failed to calculate new route: \(error.localizedDescription)")
            }
        }
    }
}
