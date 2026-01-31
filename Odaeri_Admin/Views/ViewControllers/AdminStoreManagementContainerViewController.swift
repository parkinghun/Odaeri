//
//  AdminStoreManagementContainerViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 03/01/26.
//

import UIKit
import SnapKit

final class AdminStoreManagementContainerViewController: UIViewController {
    private let dashboardController = AdminDashboardSplitViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.gray0
        addChild(dashboardController)
        view.addSubview(dashboardController.view)
        dashboardController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        dashboardController.didMove(toParent: self)
        dashboardController.show(tab: .storeManagement)
    }
}
