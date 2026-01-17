//
//  CommunityMediaBannerView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import SnapKit

final class CommunityMediaBannerView: UIView {
    var onVideoSelected: ((URL) -> Void)?

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

        cell.configure(with: items[indexPath.item])
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = min(max(page, 0), max(items.count - 1, 0))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        guard item.type == .video, let url = URL(string: item.url) else { return }
        onVideoSelected?(url)
    }
}

private final class CommunityMediaBannerCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: CommunityMediaBannerCell.self)

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let playIconView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        view.tintColor = AppColor.gray0
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
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

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        playIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(40)
        }
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
            imageView.setVideoThumbnail(url: item.url)
        }
    }
}
