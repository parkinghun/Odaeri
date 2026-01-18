//
//  StoreReviewViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class StoreReviewViewController: BaseViewController<StoreReviewViewModel> {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        label.textAlignment = .center
        label.text = "리뷰"
        return label
    }()

    override func setupUI() {
        super.setupUI()

        navigationItem.title = "리뷰"
        view.backgroundColor = AppColor.gray0

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = StoreReviewViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()
        )
        _ = viewModel.transform(input: input)
        viewDidLoadSubject.send(())
    }
}
