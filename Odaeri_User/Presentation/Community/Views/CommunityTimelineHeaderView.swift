//
//  CommunityTimelineHeaderView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class CommunityTimelineHeaderView: UIView {
    var onSortSelected: ((CommunitySortType) -> Void)? {
        didSet { sortButtonHandler = onSortSelected }
    }
    var onUserScrolledBanner: ((Int) -> Void)? {
        didSet { bannerView.onUserScrolled = onUserScrolledBanner }
    }
    var onBannerSelected: ((BannerEntity) -> Void)? {
        didSet { bannerView.onBannerSelected = onBannerSelected }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "타임라인"
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let sortButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        
        let resizedImage = AppImage.list
            .resize(to: CGSize(width: 16, height: 16))
            .withRenderingMode(.alwaysTemplate)
        
        configuration.image = resizedImage
        configuration.imagePadding = AppSpacing.xxSmall
        configuration.imagePlacement = .trailing
        configuration.baseForegroundColor = AppColor.blackSprout
        
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.caption
            return outgoing
        }
        configuration.contentInsets = .zero
        
        let button = UIButton(configuration: configuration)
        button.contentEdgeInsets = .zero
        button.configurationUpdateHandler = { button in
            var config = button.configuration ?? UIButton.Configuration.plain()
            if config.contentInsets != .zero {
                config.contentInsets = .zero
                button.configuration = config
            }
        }
        return button
    }()

    private let bannerView = BannerCarouselView()
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray30
        return view
    }()
    private let topRowView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15

        addSubview(topRowView)
        addSubview(bannerView)
        addSubview(dividerView)

        topRowView.addSubview(titleLabel)
        topRowView.addSubview(sortButton)

        topRowView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        sortButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        bannerView.snp.makeConstraints {
            $0.top.equalTo(topRowView.snp.bottom).offset(AppSpacing.medium)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(100)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(AppSpacing.medium)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
            $0.bottom.equalToSuperview()
        }

        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        updateSortButtonTitle()
    }

    func updateSortSelection(_ selection: CommunitySortType) {
        currentSort = selection
    }

    func updateBanners(_ banners: [BannerEntity]) {
        bannerView.update(banners: banners)
    }

    func scrollToBanner(at index: Int) {
        bannerView.scrollToBanner(at: index)
    }

    private var currentSort: CommunitySortType = .recent {
        didSet { updateSortButtonTitle() }
    }

    private var sortButtonHandler: ((CommunitySortType) -> Void)?

    @objc private func sortButtonTapped() {
        currentSort = currentSort == .recent ? .likes : .recent
        sortButtonHandler?(currentSort)
    }

    private func updateSortButtonTitle() {
        let title = currentSort == .recent ? "최신순" : "좋아요 순"
        sortButton.configuration?.title = title
    }
}
