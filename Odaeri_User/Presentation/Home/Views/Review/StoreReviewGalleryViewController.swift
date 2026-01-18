//
//  StoreReviewGalleryViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/19/26.
//

import UIKit
import SnapKit

final class StoreReviewGalleryViewController: UIViewController {
    private enum Segment: Int {
        case image
        case video
    }

    private var imageUrls: [String]
    private var currentSegment: Segment = .image

    private let segmentedControl = ReviewGallerySegmentedControl()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.text = "이미지가 없습니다"
        label.isHidden = true
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = AppSpacing.small
        layout.minimumLineSpacing = AppSpacing.small
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = AppColor.gray0
        view.dataSource = self
        view.register(ReviewGalleryImageCell.self, forCellWithReuseIdentifier: ReviewGalleryImageCell.reuseIdentifier)
        return view
    }()

    init(imageUrls: [String]) {
        self.imageUrls = imageUrls
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        updateEmptyState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutItemSize()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0
        navigationItem.title = "리뷰 갤러리"

        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.small)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.height.equalTo(36)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(AppSpacing.medium)
            $0.leading.trailing.bottom.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func bind() {
        segmentedControl.onSelectionChanged = { [weak self] index in
            guard let self else { return }
            self.currentSegment = index == 0 ? .image : .video
            self.collectionView.reloadData()
            self.updateEmptyState()
        }
    }

    private func updateLayoutItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = collectionView.bounds.width
        let spacing = layout.minimumInteritemSpacing
        let totalSpacing = spacing * 2
        let itemWidth = floor((width - totalSpacing) / 3)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    }

    private func updateEmptyState() {
        switch currentSegment {
        case .image:
            emptyLabel.text = "이미지가 없습니다"
            emptyLabel.isHidden = !imageUrls.isEmpty
        case .video:
            emptyLabel.text = "동영상이 없습니다"
            emptyLabel.isHidden = false
        }
    }
}

extension StoreReviewGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch currentSegment {
        case .image:
            return imageUrls.count
        case .video:
            return 0
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ReviewGalleryImageCell.reuseIdentifier,
            for: indexPath
        ) as! ReviewGalleryImageCell
        cell.configure(url: imageUrls[indexPath.item])
        return cell
    }
}
