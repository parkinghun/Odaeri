//
//  HomeCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import MapKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSelectStore(_ coordinator: HomeCoordinator, storeId: String)
}

final class HomeCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: HomeCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        let homeViewModel = HomeViewModel()
        homeViewModel.coordinator = self
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        navigationController.setViewControllers([homeViewController], animated: false)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePendingPaymentValidated(_:)),
            name: .pendingPaymentValidated,
            object: nil
        )
    }

    @objc private func handlePendingPaymentValidated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let info = userInfo["info"] as? PendingPaymentValidatedInfo else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showPendingPaymentSuccessAlert(info: info)
        }
    }

    private func showPendingPaymentSuccessAlert(info: PendingPaymentValidatedInfo) {
        let message: String
        if info.count == 1 {
            message = "\(info.storeName) 가게 결제가 최종 완료되었습니다."
        } else {
            message = "\(info.storeName) 외 \(info.count - 1)개 가게의 결제가 최종 완료되었습니다."
        }

        let alert = UIAlertController(
            title: "결제 확인 완료",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }

    func showStoreDetail(storeId: String) {
        let viewModel = ShopDetailViewModel(storeId: storeId)
        viewModel.coordinator = self
        let viewController = ShopDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showEventWeb(path: String) {
        let viewModel = EventWebViewModel(path: path)
        let viewController = EventWebViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showStoreSearch(with keyword: String? = nil) {
        let viewModel = StoreSearchViewModel(viewType: .home, initialSearchQuery: keyword)
        let viewController = StoreSearchViewController(viewModel: viewModel, viewType: .home)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func showPayment(paymentRequest: PaymentRequest) {
        let paymentCoordinator = PaymentCoordinator(
            navigationController: navigationController,
            paymentRequest: paymentRequest
        )
        paymentCoordinator.delegate = self
        addChild(paymentCoordinator)
        paymentCoordinator.start()
    }

    func showNavigation(route: MKRoute, destination: StoreEntity) {
        let navigationCoordinator = NavigationCoordinator(
            navigationController: navigationController,
            route: route,
            destination: destination
        )
        navigationCoordinator.delegate = self
        addChild(navigationCoordinator)
        navigationCoordinator.start()
    }
}

extension HomeCoordinator: PaymentCoordinatorDelegate {
    func paymentCoordinatorDidFinishPayment(_ coordinator: PaymentCoordinator, orderCode: String) {
        removeChild(coordinator)
        showAlert(title: "주문 완료", message: "주문번호: \(orderCode)")
    }

    func paymentCoordinatorDidCancelPayment(_ coordinator: PaymentCoordinator) {
        removeChild(coordinator)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension HomeCoordinator: NavigationCoordinatorDelegate {
    func navigationCoordinatorDidCancel(_ coordinator: NavigationCoordinator) {
        removeChild(coordinator)
    }

    func navigationCoordinatorDidArrive(_ coordinator: NavigationCoordinator, at store: StoreEntity) {
        removeChild(coordinator)
        showAlert(title: "도착", message: "\(store.name)에 도착했습니다.")
    }
}

extension HomeCoordinator: StoreSearchDelegate {
    func didSelectStore(storeId: String) {
        showStoreDetail(storeId: storeId)
    }
}
