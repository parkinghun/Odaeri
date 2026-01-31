//
//  MainContainerViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit

final class MainContainerViewController: UIViewController {
    private let sideListViewController = IntegratedOrderListViewController()
    private let detailViewController = AdminOrderDetailViewController()

    private let sideListView = UIView()
    private let detailContainerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6

        view.addSubview(sideListView)
        view.addSubview(detailContainerView)

        sideListView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalTo(320)
        }

        detailContainerView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(sideListView.snp.trailing)
        }

        addChild(sideListViewController)
        sideListView.addSubview(sideListViewController.view)
        sideListViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        sideListViewController.didMove(toParent: self)

        addChild(detailViewController)
        detailContainerView.addSubview(detailViewController.view)
        detailViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        detailViewController.didMove(toParent: self)
    }

    private func bind() {
        sideListViewController.onSelectOrder = { [weak self] order in
            self?.detailViewController.configure(order: order)
        }
    }
}
