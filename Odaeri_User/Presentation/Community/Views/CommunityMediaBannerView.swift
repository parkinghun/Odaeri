//
//  CommunityMediaBannerView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityMediaBannerView: UIView {
    var onVideoSelected: ((String) -> Void)?
    var isInteractionEnabled: Bool = true

    private var items: [CommunityMediaItemViewModel] = []

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = AppColor.blackSprout
        control.pageIndicatorTintColor = AppColor.gray45
        return control
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        view.allowsSelection = true
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(CommunityMediaBannerCell.self, forCellWithReuseIdentifier: CommunityMediaBannerCell.reuseIdentifier)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.itemSize = collectionView.bounds.size
    }

    private func setupUI() {
        addSubview(collectionView)
        addSubview(pageControl)

        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(AppSpacing.small)
        }
    }

    func configure(items: [CommunityMediaItemViewModel]) {
        self.items = items
        pageControl.numberOfPages = items.count
        pageControl.isHidden = items.count <= 1
        pageControl.currentPage = 0
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }
}

extension CommunityMediaBannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommunityMediaBannerCell.reuseIdentifier,
            for: indexPath
        ) as? CommunityMediaBannerCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item]
        cell.configure(with: item)
        cell.onTap = { [weak self] in
            self?.handleTap(item: item)
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = min(max(page, 0), max(items.count - 1, 0))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isInteractionEnabled else { return }
        let item = items[indexPath.item]
        handleTap(item: item)
    }

    private func handleTap(item: CommunityMediaItemViewModel) {
        guard isInteractionEnabled else { return }
        guard item.type == .video else { return }
        onVideoSelected?(item.url)
    }
}

private final class CommunityMediaBannerCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: CommunityMediaBannerCell.self)

    var onTap: (() -> Void)?

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 12
        return view
    }()

    private let playIconView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        view.tintColor = AppColor.gray0
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private let tapButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.resetImage()
        playIconView.isHidden = true
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconView)
        contentView.addSubview(tapButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        playIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(40)
        }

        tapButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tapButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    func configure(with item: CommunityMediaItemViewModel) {
        playIconView.isHidden = item.type != .video

        if item.type == .image {
            imageView.setImage(url: item.url)
            return
        }

        if let thumbnailUrl = item.thumbnailUrl {
            imageView.setImage(url: thumbnailUrl)
        } else {
            imageView.image = AppImage.default
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
