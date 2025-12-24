//
//  OrderViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class OrderViewController: BaseViewController<OrderViewModel> {
    weak var coordinator: OrderCoordinator?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오더"
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        return label
    }()

    override func setupUI() {
        super.setupUI()

        view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func bind() {
        super.bind()

        let input = OrderViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
