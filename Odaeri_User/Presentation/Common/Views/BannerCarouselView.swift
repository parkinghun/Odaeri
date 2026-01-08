//
//  BannerCarouselView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import SnapKit

final class BannerCarouselView: UIView {
    var onUserScrolled: ((Int) -> Void)?
    var onBannerSelected: ((BannerEntity) -> Void)?

    private var banners: [BannerEntity] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = AppColor.gray15
        view.dataSource = self
        view.delegate = self
        view.register(BannerCell.self, forCellWithReuseIdentifier: String(describing: BannerCell.self))
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
        layout.itemSize = CGSize(width: bounds.width, height: bounds.height)
        layout.invalidateLayout()
    }

    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func update(banners: [BannerEntity]) {
        self.banners = banners
        collectionView.reloadData()
    }

    func scrollToBanner(at index: Int) {
        guard !banners.isEmpty, index < banners.count else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension BannerCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        banners.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: BannerCell.self),
            for: indexPath
        ) as? BannerCell else {
            return UICollectionViewCell()
        }

        let banner = banners[indexPath.item]
        cell.configure(with: banner, currentIndex: indexPath.item, totalCount: banners.count)
        return cell
    }
}

extension BannerCarouselView: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        onUserScrolled?(index)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        let index = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        onUserScrolled?(index)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard banners.indices.contains(indexPath.item) else { return }
        onBannerSelected?(banners[indexPath.item])
    }
}
