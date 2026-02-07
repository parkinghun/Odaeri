//
//  ShopListHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit
import SnapKit
import Combine

final class ShopListHeaderView: UICollectionReusableView {
    var cancellables = Set<AnyCancellable>()
    enum SortType: String {
        case distance
        case orders
        case reviews

        var title: String {
            switch self {
            case .distance: return "거리순"
            case .orders: return "주문수"
            case .reviews: return "리뷰수"
            }
        }
    }

    enum FilterType {
        case all
        case picchelin
        case myPick
    }

    private let sortTypeSubject = PassthroughSubject<SortType, Never>()
    var sortTypePublisher: AnyPublisher<SortType, Never> {
        sortTypeSubject.eraseToAnyPublisher()
    }

    private let filterTypeSubject = PassthroughSubject<FilterType, Never>()
    var filterTypePublisher: AnyPublisher<FilterType, Never> {
        filterTypeSubject.eraseToAnyPublisher()
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        label.text = "내가 픽업 가게"
        return label
    }()
    
    private lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let resizedImage = AppImage.list
            .resize(to: CGSize(width: 16, height: 16))
            .withRenderingMode(.alwaysTemplate)
        config.image = resizedImage
        config.imagePadding = 4
        config.imagePlacement = .trailing
        
        var titleContainer = AttributeContainer()
        titleContainer.font = AppFont.caption
        titleContainer.foregroundColor = AppColor.blackSprout
        config.attributedTitle = AttributedString("거리순", attributes: titleContainer)
        
        let button = UIButton(configuration: config)
        button.tintColor = AppColor.blackSprout
        button.contentHorizontalAlignment = .trailing
        
        button.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let picchelinToggle = FilterToggleButton(title: "픽슐랭")
    private let myPickToggle = FilterToggleButton(title: "My Pick")
    
    private var currentSortType: SortType = .distance
    private var hasSentInitialFilter = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupToggleBindings()
        picchelinToggle.isSelected = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(sortButton)
        addSubview(picchelinToggle)
        addSubview(myPickToggle)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7.5)
            make.leading.equalToSuperview()
        }
        
        sortButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview()
        }
        
        picchelinToggle.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.large)
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview().inset(AppSpacing.small)
        }
        
        myPickToggle.snp.makeConstraints { make in
            make.centerY.equalTo(picchelinToggle)
            make.leading.equalTo(picchelinToggle.snp.trailing).offset(AppSpacing.small)
        }
    }
    
    private func setupToggleBindings() {
        picchelinToggle.tapPublisher
            .sink { [weak self] isSelected in
                guard let self = self else { return }
                if isSelected {
                    self.picchelinToggle.isSelected = true
                    self.myPickToggle.isSelected = false
                    self.filterTypeSubject.send(.picchelin)
                }
            }
            .store(in: &cancellables)

        myPickToggle.tapPublisher
            .sink { [weak self] isSelected in
                guard let self = self else { return }
                if isSelected {
                    self.myPickToggle.isSelected = true
                    self.picchelinToggle.isSelected = false
                    self.filterTypeSubject.send(.myPick)
                }
            }
            .store(in: &cancellables)
    }

    func applyInitialFilterIfNeeded() {
        guard !hasSentInitialFilter else { return }
        hasSentInitialFilter = true
        picchelinToggle.isSelected = true
        myPickToggle.isSelected = false
        filterTypeSubject.send(.picchelin)
    }
    
    @objc private func sortButtonTapped() {
        switch currentSortType {
        case .distance:
            currentSortType = .orders
        case .orders:
            currentSortType = .reviews
        case .reviews:
            currentSortType = .distance
        }

        guard var updatedConfig = sortButton.configuration else { return }

        var titleContainer = AttributeContainer()
        titleContainer.font = AppFont.caption
        titleContainer.foregroundColor = AppColor.blackSprout

        updatedConfig.attributedTitle = AttributedString(currentSortType.title, attributes: titleContainer)

        sortButton.configuration = updatedConfig
        sortTypeSubject.send(currentSortType)
    }
}
