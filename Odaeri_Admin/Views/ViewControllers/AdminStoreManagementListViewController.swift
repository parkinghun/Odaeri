//
//  AdminStoreManagementListViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import UIKit
import Combine
import SnapKit

final class AdminStoreManagementListViewController: UIViewController {
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let selectionSubject = PassthroughSubject<AdminStoreManagementItem, Never>()
    private var store: StoreEntity?
    private var selectedItem: AdminStoreManagementItem = .storeInfo

    var viewDidLoadPublisher: AnyPublisher<Void, Never> {
        viewDidLoadSubject.eraseToAnyPublisher()
    }

    var selectionPublisher: AnyPublisher<AdminStoreManagementItem, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "가게 관리"
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = AppColor.gray15
        tableView.register(AdminStoreManagementCell.self, forCellReuseIdentifier: AdminStoreManagementCell.reuseIdentifier)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "가게 정보를 불러오는 중입니다."
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewDidLoadSubject.send(())
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray15
        navigationItem.titleView = titleLabel

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundView = emptyLabel
    }

    func updateStore(_ store: StoreEntity?) {
        self.store = store
        tableView.reloadData()
        emptyLabel.isHidden = store != nil
    }

    func updateSelection(_ item: AdminStoreManagementItem) {
        selectedItem = item
        tableView.reloadData()
    }
}

extension AdminStoreManagementListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let store else { return 0 }
        switch section {
        case 0:
            return 1
        default:
            return store.menuList.count + 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "가게 정보" : "메뉴 목록"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminStoreManagementCell.reuseIdentifier,
            for: indexPath
        ) as! AdminStoreManagementCell

        guard let store else { return cell }
        if indexPath.section == 0 {
            cell.configure(title: "가게 정보 수정", subtitle: store.name, isSelected: selectedItem == .storeInfo)
        } else {
            if indexPath.row == 0 {
                cell.configure(title: "메뉴 등록", subtitle: "새 메뉴 추가", isSelected: selectedItem == .addMenu)
            } else {
                let menu = store.menuList[indexPath.row - 1]
                let subtitle = "\(menu.formattedPrice) · \(menu.category)"
                let isSelected = selectedItem == .menu(menu)
                cell.configure(title: menu.name, subtitle: subtitle, isSelected: isSelected)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let store else { return }
        if indexPath.section == 0 {
            selectedItem = .storeInfo
        } else {
            if indexPath.row == 0 {
                selectedItem = .addMenu
            } else {
                selectedItem = .menu(store.menuList[indexPath.row - 1])
            }
        }
        selectionSubject.send(selectedItem)
        tableView.reloadData()
    }
}

private final class AdminStoreManagementCell: UITableViewCell {
    static let reuseIdentifier = "AdminStoreManagementCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let containerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = AppColor.gray15

        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColor.gray30.cgColor
        containerView.backgroundColor = AppColor.gray0

        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        subtitleLabel.font = AppFont.caption1
        subtitleLabel.textColor = AppColor.gray60

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4

        contentView.addSubview(containerView)
        containerView.addSubview(stack)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.medium)
        }

        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.medium)
        }
    }

    func configure(title: String, subtitle: String, isSelected: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        containerView.layer.borderColor = isSelected ? AppColor.deepSprout.cgColor : AppColor.gray30.cgColor
        containerView.backgroundColor = isSelected ? AppColor.brightSprout : AppColor.gray0
    }
}
