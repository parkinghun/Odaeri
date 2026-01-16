//
//  BaseViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit
import Combine
import SnapKit

class BaseViewController<VM: ViewModelType>: UIViewController, UIGestureRecognizerDelegate {

    let viewModel: VM
    var cancellables = Set<AnyCancellable>()
    
    private(set) lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = AppColor.blackSprout
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    open var navigationBarHidden: Bool {
        return navigationController?.viewControllers.count ?? 0 <= 1
    }
    
    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(navigationBarHidden, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
        setupNavigationBar()
        setupLoadingIndicator()
        setupKeyboardDismissGesture()
        setupUI()
        bind()
    }
    
    func setupUI() {
    }
    
    func bind() {
    }

    func setKeyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode, for scrollView: UIScrollView) {
        scrollView.keyboardDismissMode = mode
    }
    
    private func setupNavigationBar() {
        guard let navigationController = navigationController,
              navigationController.viewControllers.count > 1 else {
            return
        }
        
        navigationItem.hidesBackButton = true
        
        let backButton = createBackButton()
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    private func createBackButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(AppImage.chevron, for: .normal)
        button.tintColor = AppColor.gray0
        button.snp.makeConstraints { make in
            make.size.equalTo(32)
        }
        return button
    }
    
    func setRightBarButtons(_ buttons: [UIButton]) {
        let barButtonItems = buttons.map { UIBarButtonItem(customView: $0) }
        navigationItem.rightBarButtonItems = barButtonItems
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl {
            return false
        }
        if touch.view is UITextView {
            return false
        }

        var currentView = touch.view?.superview
        while let view = currentView {
            if view is UIControl || view is UITextView {
                return false
            }
            currentView = view.superview
        }

        return true
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
