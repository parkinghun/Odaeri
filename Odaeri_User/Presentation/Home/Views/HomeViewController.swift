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
     locationView - AppImage.location 문래역, 영등포구(위치) AppImage.detail  (HStack)
     서치바
     인기검색어
     
     카테고리
     실시간 인기 맛집
     배너
     
     내가 픽업가게 (거리순)
     (픽슐랭 / 마이픽)
     */
    
    private let locationView = LocationView()
    private let searchBar = SearchBar()
    
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppColor.brightSprout
        
        view.addSubview(locationView)
        view.addSubview(searchBar)
        
        locationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            $0.leading.equalToSuperview().offset(AppSpacing.screenMargin)
            $0.height.equalTo(32)
        }
        searchBar.snp.makeConstraints {
            $0.top.equalTo(locationView.snp.bottom).offset(AppSpacing.small)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
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
    }
}
