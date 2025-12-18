//
//  BaseViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit
import Combine

class BaseViewController: UIViewController {
    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
        setupUI()
        bind()
    }

    func setupUI() {
    }

    func bind() {
    }

    deinit {
        cancellables.removeAll()
    }
}
