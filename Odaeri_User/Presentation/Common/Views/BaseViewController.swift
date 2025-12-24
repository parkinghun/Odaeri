//
//  BaseViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit
import Combine

class BaseViewController<VM: ViewModelType>: UIViewController {
  
    let viewModel: VM
    var cancellables = Set<AnyCancellable>()

    private(set) lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = AppColor.blackSprout
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
        setupLoadingIndicator()
        setupUI()
        bind()
    }

    func setupUI() {
    }

    func bind() {
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            view.endEditing(true)
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }

    func showAlert(title: String, message: String, confirmTitle: String = "확인") {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: confirmTitle, style: .default))
        present(alert, animated: true)
    }

    deinit {
        cancellables.removeAll()
    }
}
