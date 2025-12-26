//
//  HomeViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class HomeViewController: BaseViewController<HomeViewModel> {
    weak var coordinator: HomeCoordinator?
    
    /*
     카테고리
     실시간 인기 맛집
     배너
     
     내가 픽업가게 (거리순)
     (픽슐랭 / 마이픽)
     */
    
    private let locationView = LocationView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let searchBar = SearchBar()
    private let trendingSearchTickerView = TrendingSearchTickerView()

    private lazy var modalMainView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private let categoryView = CategoryView()

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.brightSprout

        view.addSubview(locationView)
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addSubview(searchBar)
        contentView.addSubview(trendingSearchTickerView)
        contentView.addSubview(modalMainView)

        modalMainView.addSubview(categoryView)

        locationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.height.equalTo(32)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(locationView.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        trendingSearchTickerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(AppSpacing.medium)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        modalMainView.snp.makeConstraints {
            $0.top.equalTo(trendingSearchTickerView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
            $0.bottom.equalToSuperview()
        }

        categoryView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }
    }
    
    override func bind() {
        super.bind()

        let input = HomeViewModel.Input()
        let output = viewModel.transform(input: input)

        locationView.tapPublisher
            .sink { [weak self] in
                // TODO: 위치 선택 화면으로 이동
                print("Location tapped")
            }
            .store(in: &cancellables)

        categoryView.categoryTapPublisher
            .sink { category in
                print("Selected category: \(category.title)")
                // TODO: 선택된 카테고리에 따라 필터링
            }
            .store(in: &cancellables)
    }
}
