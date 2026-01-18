//
//  StoreReviewImageListView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class StoreReviewImageListView: UIView {
    private enum Layout {
        static let itemSize = CGSize(width: 88, height: 88)
        static let spacing: CGFloat = 8
    }

    private var imageUrls: [String] = []
    private var currentImageUrls: [String] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.spacing
        layout.itemSize = Layout.itemSize
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.register(StoreReviewImageCell.self, forCellWithReuseIdentifier: StoreReviewImageCell.reuseIdentifier)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(imageUrls: [String]) {
        if currentImageUrls == imageUrls {
            return
        }
        currentImageUrls = imageUrls
        self.imageUrls = imageUrls
        collectionView.reloadData()
    }
}

extension StoreReviewImageListView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: StoreReviewImageCell.reuseIdentifier,
            for: indexPath
        ) as! StoreReviewImageCell
        cell.configure(url: imageUrls[indexPath.item])
        return cell
    }
}
