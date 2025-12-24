//
//  SearchBar.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import SnapKit

final class SearchBar: BaseView {
    private let borderColor: UIColor
    private let placeholder: String

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.cgColor
        view.layer.cornerRadius = 20
        view.backgroundColor = AppColor.gray0
        return view
    }()

    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = placeholder
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.font = AppFont.body2
        searchBar.backgroundImage = UIImage()
        return searchBar
    }()

    init(
        borderColor: UIColor = AppColor.deepSprout,
        placeholder: String = "검색어를 입력해주세요."
    ) {
        self.borderColor = borderColor
        self.placeholder = placeholder
        super.init(frame: .zero)
    }

    override func setupView() {
        addSubview(containerView)
        containerView.addSubview(searchBar)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(40)
        }

        searchBar.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
