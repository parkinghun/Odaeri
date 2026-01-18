//
//  StoreReviewViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit

final class StoreReviewViewController: BaseViewController<StoreReviewViewModel> {
    private enum Section: Int, CaseIterable {
        case photo
        case reviews
    }

    private var reviewItems: [StoreReviewItemViewModel] = []
    private let orderChangedSubject = CurrentValueSubject<StoreReviewOrder, Never>(.latest)
    private let loadMoreSubject = PassthroughSubject<Void, Never>()
    private let editReviewSubject = PassthroughSubject<StoreReviewItemViewModel, Never>()
    private let reviewUpdatedSubject = PassthroughSubject<StoreReviewDetailEntity, Never>()
    private let deleteReviewSubject = PassthroughSubject<String, Never>()
    private let profileTapSubject = PassthroughSubject<StoreReviewProfileTarget, Never>()
    private let galleryTapSubject = PassthroughSubject<Void, Never>()
    private var photoUrls: [String] = []

    private let summaryView = StoreReviewSummaryView()
    private let emptyView: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.text = "리뷰가 없습니다"
        label.isHidden = true
        return label
    }()

    private lazy var orderControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StoreReviewOrder.allCases.map { $0.title })
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(handleOrderChanged), for: .valueChanged)
        return control
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColor.gray0
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.register(StoreReviewCell.self, forCellReuseIdentifier: StoreReviewCell.reuseIdentifier)
        tableView.register(StoreReviewPhotoPreviewCell.self, forCellReuseIdentifier: StoreReviewPhotoPreviewCell.reuseIdentifier)
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    override func setupUI() {
        super.setupUI()

        navigationItem.title = "리뷰"
        view.backgroundColor = AppColor.gray0

        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        configureTableHeader()
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = StoreReviewViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            loadMore: loadMoreSubject.eraseToAnyPublisher(),
            orderChanged: orderChangedSubject.eraseToAnyPublisher(),
            editReview: editReviewSubject.eraseToAnyPublisher(),
            reviewUpdated: reviewUpdatedSubject.eraseToAnyPublisher(),
            deleteReview: deleteReviewSubject.eraseToAnyPublisher(),
            profileTapped: profileTapSubject.eraseToAnyPublisher(),
            galleryTapped: galleryTapSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.summaryView.configure(with: summary)
                self?.updateTableHeaderLayout()
            }
            .store(in: &cancellables)

        output.reviews
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.reviewItems = items
                self?.tableView.reloadData()
                self?.emptyView.isHidden = !items.isEmpty
            }
            .store(in: &cancellables)

        output.photoUrls
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urls in
                self?.photoUrls = urls
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "오류", message: message)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .reviewUpdated)
            .compactMap { $0.userInfo?["review"] as? StoreReviewDetailEntity }
            .sink { [weak self] review in
                self?.reviewUpdatedSubject.send(review)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeaderLayout()
    }

    private func configureTableHeader() {
        let headerContainer = UIView()
        headerContainer.backgroundColor = AppColor.gray0
        headerContainer.addSubview(summaryView)
        headerContainer.addSubview(orderControl)

        summaryView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        orderControl.snp.makeConstraints {
            $0.top.equalTo(summaryView.snp.bottom).offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.bottom.equalToSuperview().offset(-AppSpacing.medium)
            $0.height.equalTo(36)
        }

        tableView.tableHeaderView = headerContainer
        updateTableHeaderLayout()
    }

    private func updateTableHeaderLayout() {
        guard let header = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(targetSize).height
        if header.frame.height != height {
            header.frame.size.height = height
            tableView.tableHeaderView = header
        }
    }

    @objc private func handleOrderChanged() {
        let selectedIndex = orderControl.selectedSegmentIndex
        let orders = StoreReviewOrder.allCases
        let order = selectedIndex < orders.count ? orders[selectedIndex] : .latest
        orderChangedSubject.send(order)
    }
}

extension StoreReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .photo:
            return photoUrls.isEmpty ? 0 : 1
        case .reviews:
            return reviewItems.count
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .photo:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: StoreReviewPhotoPreviewCell.reuseIdentifier,
                for: indexPath
            ) as! StoreReviewPhotoPreviewCell
            cell.configure(imageUrls: photoUrls)
            cell.onGalleryTapped = { [weak self] in
                self?.galleryTapSubject.send(())
            }
            return cell
        case .reviews:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: StoreReviewCell.reuseIdentifier,
                for: indexPath
            ) as! StoreReviewCell
            let item = reviewItems[indexPath.row]
            cell.configure(with: item)
            cell.onMoreTapped = { [weak self] in
                self?.presentReviewActions(for: item)
            }
            cell.cancellables.removeAll()
            cell.profileTapPublisher
                .sink { [weak self] in
                    let target = StoreReviewProfileTarget(
                        userId: item.creatorUserId,
                        nick: item.creatorName,
                        profileImage: item.creatorProfileUrl
                    )
                    self?.profileTapSubject.send(target)
                }
                .store(in: &cell.cancellables)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section), section == .reviews else { return }
        let threshold = reviewItems.count - 2
        if indexPath.row >= threshold {
            loadMoreSubject.send(())
        }
    }

    private func presentReviewActions(for item: StoreReviewItemViewModel) {
        guard item.isMe else { return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "수정하기", style: .default) { _ in
            self.editReviewSubject.send(item)
        })
        alert.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
            self?.deleteReviewSubject.send(item.reviewId)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}
