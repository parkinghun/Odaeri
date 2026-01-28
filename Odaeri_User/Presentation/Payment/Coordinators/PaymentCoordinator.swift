//
//  PaymentCoordinator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit

protocol PaymentCoordinatorDelegate: AnyObject {
    func paymentCoordinatorDidFinishPayment(_ coordinator: PaymentCoordinator, orderCode: String)
    func paymentCoordinatorDidCancelPayment(_ coordinator: PaymentCoordinator)
}

final class PaymentCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    weak var delegate: PaymentCoordinatorDelegate?

    private let paymentRequest: PaymentRequest
    private let paymentService: PaymentService

    init(
        navigationController: UINavigationController,
        paymentRequest: PaymentRequest,
        paymentService: PaymentService
    ) {
        self.navigationController = navigationController
        self.paymentRequest = paymentRequest
        self.paymentService = paymentService
    }

    func start() {
        let viewModel = PaymentViewModel(
            paymentRequest: paymentRequest,
            paymentService: paymentService
        )
        viewModel.coordinator = self
        let viewController = PaymentViewController(viewModel: viewModel)

        let paymentNavigationController = UINavigationController(rootViewController: viewController)
        paymentNavigationController.modalPresentationStyle = .fullScreen

        navigationController.present(paymentNavigationController, animated: true)
    }

    func showPaymentSuccess(orderCode: String) {
        let alert = UIAlertController(
            title: "결제 완료",
            message: "결제가 성공적으로 완료되었습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.navigationController.dismiss(animated: true) {
                self.delegate?.paymentCoordinatorDidFinishPayment(self, orderCode: orderCode)
            }
        })

        navigationController.presentedViewController?.present(alert, animated: true)
    }

    func showPaymentFailure(error: PaymentError) {
        let alert = UIAlertController(
            title: "결제 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.navigationController.dismiss(animated: true) {
                self.delegate?.paymentCoordinatorDidCancelPayment(self)
            }
        })

        navigationController.presentedViewController?.present(alert, animated: true)
    }

    func showRetryAlert(error: PaymentError, retryHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "결제 오류",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "재시도", style: .default) { _ in
            retryHandler()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.navigationController.dismiss(animated: true) {
                self.delegate?.paymentCoordinatorDidCancelPayment(self)
            }
        })

        navigationController.presentedViewController?.present(alert, animated: true)
    }
}
