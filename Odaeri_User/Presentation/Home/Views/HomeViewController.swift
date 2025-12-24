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
     위치
     서치바
     인기검색어
     
     카테고리
     실시간 인기 맛집
     배너
     
     내가 픽업가게 (거리순)
     (픽슐랭 / 마이픽)
     
     
     
     */

    override func setupUI() {
        super.setupUI()

    }

    override func bind() {
        super.bind()

        let input = HomeViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
