//
//  StreamingListViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import UIKit
import Combine
import SnapKit

final class StreamingListViewController: BaseViewController<StreamingListViewModel> {
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = AppColor.gray0
        table.separatorStyle = .none
        table.register(StreamingListCell.self, forCellReuseIdentifier: StreamingListCell.reuseIdentifier)
        table.refreshControl = refreshControl
        return table
    }()

    private let refreshControl = UIRefreshControl()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let loadMoreSubject = PassthroughSubject<Void, Never>()
    private let itemSelectedSubject = PassthroughSubject<String, Never>()

    private var videoEntities: [VideoEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send(())
    }

    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppColor.gray0
        title = "영상 목록"

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
    }

    @objc private func refreshTriggered() {
        refreshSubject.send(())
    }

    override func bind() {
        super.bind()

        let input = StreamingListViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refreshTriggered: refreshSubject.eraseToAnyPublisher(),
            loadMore: loadMoreSubject.eraseToAnyPublisher(),
            itemSelected: itemSelectedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.videoEntities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entities in
                self?.videoEntities = entities
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)
    }
}

extension StreamingListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoEntities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StreamingListCell.reuseIdentifier,
            for: indexPath
        ) as? StreamingListCell else {
            return UITableViewCell()
        }

        let entity = videoEntities[indexPath.row]
        let display = StreamingVideoDisplay(
            videoId: entity.videoId,
            title: entity.title,
            description: entity.description,
            likeCountText: "\(entity.likeCount)",
            viewCountText: "\(entity.viewCount)",
            isLiked: entity.isLiked,
            createdAtText: entity.createdAt?.toRelativeTime ?? "",
            thumbnailUrl: entity.thumbnailUrl
        )
        cell.configure(with: display, durationText: entity.durationText)
        return cell
    }
}

extension StreamingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let videoId = videoEntities[indexPath.row].videoId
        itemSelectedSubject.send(videoId)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight - 100 {
            loadMoreSubject.send(())
        }
    }
}
