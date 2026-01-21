//
//  AdminBootstrapViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine

final class AdminBootstrapViewController: UIViewController {
    private let storeService: AdminStoreService
    private var cancellables = Set<AnyCancellable>()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var hasCheckedStore = false

    var onReady: (() -> Void)?

    init(storeService: AdminStoreService = AdminStoreService()) {
        self.storeService = storeService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicator.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasCheckedStore else { return }
        hasCheckedStore = true
        checkStore()
    }

    private func checkStore() {
        guard let storeId = AdminStoreSession.shared.storeId else {
            presentRegistrationFlow()
            return
        }

        storeService.fetchStoreDetail(storeId: storeId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure = completion {
                        AdminStoreSession.shared.clearStoreId()
                        self.presentRegistrationFlow()
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.activityIndicator.stopAnimating()
                    self?.onReady?()
                }
            )
            .store(in: &cancellables)
    }

    private func presentRegistrationFlow() {
        activityIndicator.stopAnimating()
        let alert = UIAlertController(
            title: "가게 등록 필요",
            message: "가게를 먼저 등록해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "등록하기", style: .default) { [weak self] _ in
            self?.showRegistration()
        })
        present(alert, animated: true)
    }

    private func showRegistration() {
        let registerViewController = AdminStoreRegistrationViewController()
        registerViewController.onRegistered = { [weak self] store in
            AdminStoreSession.shared.storeId = store.storeId
            self?.dismiss(animated: true) {
                self?.onReady?()
            }
        }
        let navigationController = UINavigationController(rootViewController: registerViewController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
}
