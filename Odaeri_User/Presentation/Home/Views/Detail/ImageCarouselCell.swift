//
//  ImageCarouselCell.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/6/26.
//

import UIKit
import SnapKit

final class ImageCarouselCell: BaseCollectionViewCell {
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColor.gray30
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StoreImageCell.self, forCellWithReuseIdentifier: "StoreImageCell")
        return collectionView
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = AppColor.gray0
        control.pageIndicatorTintColor = AppColor.gray60
        control.isUserInteractionEnabled = false
        return control
    }()

    private var storeImages: [String] = []

    override func setupUI() {
        super.setupUI()
        contentView.addSubview(imageCollectionView)
        contentView.addSubview(pageControl)

        imageCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(AppSpacing.xxxLarge)
        }
    }

    func configure(with store: StoreEntity) {
        storeImages = store.storeImageUrls
        pageControl.numberOfPages = storeImages.count
        pageControl.currentPage = 0
        imageCollectionView.reloadData()
    }
}

extension ImageCarouselCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storeImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StoreImageCell", for: indexPath) as! StoreImageCell
        cell.configure(with: storeImages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = pageIndex
    }
}
