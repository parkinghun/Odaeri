//
//  UserProfileViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit
import SwiftUI

final class UserProfileViewController: BaseViewController<UserProfileViewModel> {
    private let headerView = UserProfileHeaderView()
    private let emptyView = UserProfileEmptyView()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let primaryButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let moreTappedSubject = PassthroughSubject<Void, Never>()
    private let logoutTappedSubject = PassthroughSubject<Void, Never>()
    private let emptyActionTappedSubject = PassthroughSubject<Void, Never>()
    private let postActionSubject = PassthroughSubject<UserProfilePostAction, Never>()

    private var posts: [CommunityPostEntity] = []
    private var isMe = false

    override var navigationBarHidden: Bool { false }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColor.gray0
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    private enum Layout {
        static let headerTop: CGFloat = 12
        static let headerSide: CGFloat = 20
        static let headerBottom: CGFloat = 12
        static let itemSpacing: CGFloat = 2
        static let sectionInset: CGFloat = 2
        static let columns: CGFloat = 3
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0
        navigationItem.title = "프로필"
        view.addSubview(headerView)
        view.addSubview(collectionView)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.headerTop)
            $0.leading.trailing.equalToSuperview().inset(Layout.headerSide)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(Layout.headerBottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        collectionView.register(
            UserProfilePostCell.self,
            forCellWithReuseIdentifier: UserProfilePostCell.reuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundView = emptyView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send(())
    }

    override func bind() {
        super.bind()

        let input = UserProfileViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            primaryButtonTapped: primaryButtonTappedSubject.eraseToAnyPublisher(),
            moreTapped: moreTappedSubject.eraseToAnyPublisher(),
            logoutTapped: logoutTappedSubject.eraseToAnyPublisher(),
            emptyActionTapped: emptyActionTappedSubject.eraseToAnyPublisher(),
            postAction: postActionSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.header
            .receive(on: DispatchQueue.main)
            .sink { [weak self] header in
                self?.headerView.configure(with: header)
            }
            .store(in: &cancellables)

        output.navigationItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.configureNavigationItem(item)
            }
            .store(in: &cancellables)

        output.posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.posts = posts
                self?.collectionView.reloadData()
                self?.updateEmptyView()
            }
            .store(in: &cancellables)

        output.isLoading
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.error
            .sink { [weak self] message in
                self?.showAlert(title: "오류", message: message)
            }
            .store(in: &cancellables)

        headerView.actionTapped
            .sink { [weak self] _ in
                self?.primaryButtonTappedSubject.send(())
            }
            .store(in: &cancellables)

        emptyView.actionTapped
            .sink { [weak self] _ in
                self?.emptyActionTappedSubject.send(())
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    private func configureNavigationItem(_ item: UserProfileNavigationItem) {
        let button = UIButton(type: .system)
        switch item {
        case .myMenu:
            button.setImage(rotatedMenuImage(), for: .normal)
            button.tintColor = AppColor.gray90
            isMe = true
            button.menu = makeMyMenu()
            button.showsMenuAsPrimaryAction = true
        case .otherMenu:
            button.setImage(AppImage.moreHorizontal, for: .normal)
            button.tintColor = AppColor.gray90
            isMe = false
            button.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        }

        button.snp.makeConstraints { $0.size.equalTo(28) }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        updateEmptyView()
    }

    private func updateEmptyView() {
        emptyView.configure(isMe: isMe)
        emptyView.isHidden = !posts.isEmpty
        collectionView.backgroundView = posts.isEmpty ? emptyView : nil
    }

    @objc private func moreTapped() {
        moreTappedSubject.send(())
    }

    private func makeMyMenu() -> UIMenu {
        var actions: [UIMenuElement] = []

        if #available(iOS 16.2, *) {
            let liveActivityAction = UIAction(
                title: "라이브 액티비티 테스트",
                image: UIImage(systemName: "bell.badge.fill")
            ) { [weak self] _ in
                self?.showLiveActivityTest()
            }
            actions.append(liveActivityAction)
        }

        let logoutAction = UIAction(title: "로그아웃", attributes: .destructive) { [weak self] _ in
            self?.logoutTappedSubject.send(())
        }
        actions.append(logoutAction)

        return UIMenu(children: actions)
    }

    @available(iOS 16.2, *)
    private func showLiveActivityTest() {
        let testView = LiveActivityTestView()
        let hostingController = UIHostingController(rootView: testView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(hostingController, animated: true)
    }

    private func rotatedMenuImage() -> UIImage? {
        let image = AppImage.moreHorizontal
        
        let size = CGSize(width: AppImage.moreHorizontal.size.height, height: AppImage.moreHorizontal.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            context.cgContext.rotate(by: .pi / 2)
            image.draw(
                in: CGRect(
                    x: -image.size.width / 2,
                    y: -image.size.height / 2,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
    }
}

extension UserProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UserProfilePostCell.reuseIdentifier,
            for: indexPath
        ) as? UserProfilePostCell else {
            return UICollectionViewCell()
        }

        let post = posts[indexPath.item]
        cell.configure(imageUrl: post.files.first)
        return cell
    }
}

extension UserProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = Layout.sectionInset * 2 + Layout.itemSpacing * (Layout.columns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / Layout.columns
        return CGSize(width: width, height: width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: Layout.sectionInset,
            left: Layout.sectionInset,
            bottom: Layout.sectionInset,
            right: Layout.sectionInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard isMe else { return nil }
        let postId = posts[indexPath.item].postId
        return UIContextMenuConfiguration(identifier: postId as NSString, previewProvider: nil) { _ in
            let editAction = UIAction(title: "수정") { [weak self] _ in
                self?.postActionSubject.send(.edit(postId))
            }
            let deleteAction = UIAction(title: "삭제", attributes: .destructive) { [weak self] _ in
                self?.postActionSubject.send(.delete(postId))
            }
            return UIMenu(children: [editAction, deleteAction])
        }
    }
}
