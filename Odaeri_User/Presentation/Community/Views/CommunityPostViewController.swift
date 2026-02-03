//
//  CommunityPostViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/16/26.
//

import UIKit
import SnapKit
import Combine
import PhotosUI
import AVFoundation

final class CommunityPostViewController: BaseViewController<CommunityPostViewModel> {
    private let viewType: CommunityPostViewType

    @Published private var selectedCategory: Category?
    @Published private var selectedStoreId: String?
    private var selectedStoreName: String?

    private let mediaItemsSubject = CurrentValueSubject<[CommunityPostMediaItem], Never>([])
    private var mediaItems: [CommunityPostMediaItem] = [] {
        didSet {
            mediaCollectionView.reloadData()
            updateDoneButtonState()
            mediaItemsSubject.send(mediaItems)
        }
    }

    private let storeButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let doneButtonTappedSubject = PassthroughSubject<Void, Never>()

    private var doneButton: UIButton?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("카테고리 선택", for: .normal)
        button.setTitleColor(AppColor.gray75, for: .normal)
        button.titleLabel?.font = AppFont.body2
        button.contentHorizontalAlignment = .left
        button.backgroundColor = AppColor.gray15
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }()

    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "제목을 입력해주세요"
        textField.font = AppFont.body1
        textField.textColor = AppColor.gray90
        textField.backgroundColor = AppColor.gray15
        textField.layer.cornerRadius = 8
        textField.setLeftPadding(12)
        return textField
    }()

    private let storeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("방문한 가게를 검색해주세요", for: .normal)
        button.setTitleColor(AppColor.gray75, for: .normal)
        button.titleLabel?.font = AppFont.body2
        button.contentHorizontalAlignment = .left
        button.backgroundColor = AppColor.gray15
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }()

    private let contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = AppFont.body2
        textView.textColor = AppColor.gray90
        textView.backgroundColor = AppColor.gray15
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    private let contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "내용을 입력해주세요"
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        return label
    }()

    private lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.mediaItemSpacing
        layout.minimumInteritemSpacing = Layout.mediaItemSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            categoryButton,
            titleTextField,
            storeButton,
            contentTextView,
            mediaCollectionView
        ])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.large
        return stackView
    }()

    private enum Layout {
        static let horizontalInset: CGFloat = AppSpacing.screenMargin
        static let mediaSectionHeight: CGFloat = 96
        static let mediaItemSize = CGSize(width: 88, height: 88)
        static let mediaItemSpacing: CGFloat = 12
        static let maxMediaCount = 5
    }

    init(viewType: CommunityPostViewType, viewModel: CommunityPostViewModel) {
        self.viewType = viewType
        super.init(viewModel: viewModel)
    }

    override func setupUI() {
        super.setupUI()

        navigationItem.title = viewType.navigationTitle
        configureNavigationItems()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalToSuperview().offset(-AppSpacing.large)
        }

        titleTextField.snp.makeConstraints { $0.height.equalTo(44) }
        storeButton.snp.makeConstraints { $0.height.equalTo(44) }
        contentTextView.snp.makeConstraints { $0.height.equalTo(180) }
        mediaCollectionView.snp.makeConstraints { $0.height.equalTo(Layout.mediaSectionHeight) }

        contentTextView.addSubview(contentPlaceholderLabel)
        contentPlaceholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(12)
        }

        contentTextView.delegate = self

        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        storeButton.addTarget(self, action: #selector(storeButtonTapped), for: .touchUpInside)

        configureCategoryMenu()
        configureMediaCollectionView()
        setupTextFieldDelegates()
        populateInitialDataIfNeeded()
    }

    override func bind() {
        super.bind()

        let categoryPublisher = $selectedCategory
            .map { $0?.title }
            .eraseToAnyPublisher()

        let titlePublisher = titleTextField.publisher(for: \.text)
            .eraseToAnyPublisher()

        let contentPublisher = contentTextView.publisher(for: \.text)
            .eraseToAnyPublisher()

        let storeIdPublisher = $selectedStoreId.eraseToAnyPublisher()

        let storeNamePublisher = Just(selectedStoreName)
            .merge(with: $selectedStoreId.map { [weak self] _ in self?.selectedStoreName })
            .eraseToAnyPublisher()

        let input = CommunityPostViewModel.Input(
            category: categoryPublisher,
            title: titlePublisher,
            content: contentPublisher,
            storeId: storeIdPublisher,
            storeName: storeNamePublisher,
            mediaItems: mediaItemsSubject.eraseToAnyPublisher(),
            storeButtonTapped: storeButtonTappedSubject.eraseToAnyPublisher(),
            doneButtonTapped: doneButtonTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.isDoneButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.doneButton?.isEnabled = isEnabled
                self?.doneButton?.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.initialMediaItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                print("[CommunityPostViewController] Received initial media items: \(items.count)")
                for (index, item) in items.enumerated() {
                    switch item.kind {
                    case .image:
                        print("  [\(index)] Image")
                    case .video:
                        print("  [\(index)] Video")
                    case let .remote(url, thumbnailUrl, isVideo):
                        print("  [\(index)] Remote - isVideo: \(isVideo), url: \(url), thumbnail: \(thumbnailUrl ?? "nil")")
                    }
                }
                self?.mediaItems = items
            }
            .store(in: &cancellables)
    }

    func updateSelectedStore(id: String, name: String) {
        selectedStoreId = id
        selectedStoreName = name
        storeButton.setTitle(name, for: .normal)
        storeButton.setTitleColor(AppColor.gray90, for: .normal)
        updateDoneButtonState()
    }

    @objc private func categoryButtonTapped() {
    }

    @objc private func storeButtonTapped() {
        storeButtonTappedSubject.send()
    }

    @objc private func doneButtonTapped() {
        doneButtonTappedSubject.send()
    }

    private func configureNavigationItems() {
        let button = UIButton(type: .system)
        button.setTitle("완료", for: .normal)
        button.setTitleColor(AppColor.blackSprout, for: .normal)
        button.titleLabel?.font = AppFont.body2Bold
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        self.doneButton = button
        setRightBarButtons([button])
    }

    private func updateDoneButtonState() {
        let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let content = contentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let isValid = selectedCategory != nil &&
                      !title.isEmpty &&
                      selectedStoreId != nil &&
                      !content.isEmpty

        if let postToEdit = viewModel.postToEdit {
            let categoryChanged = selectedCategory?.title != postToEdit.category
            let titleChanged = title != postToEdit.title
            let contentChanged = content != postToEdit.content
            let storeChanged = selectedStoreId != postToEdit.store.storeId

            let hasChanges = categoryChanged || titleChanged || contentChanged || storeChanged
            doneButton?.isEnabled = isValid && hasChanges
            doneButton?.alpha = (isValid && hasChanges) ? 1.0 : 0.5
        } else {
            doneButton?.isEnabled = isValid
            doneButton?.alpha = isValid ? 1.0 : 0.5
        }
    }

    private func configureCategoryMenu() {
        let actions = Category.allCases.map { category in
            UIAction(title: category.title) { [weak self] _ in
                self?.selectedCategory = category
                self?.categoryButton.setTitle(category.title, for: .normal)
                self?.categoryButton.setTitleColor(AppColor.gray90, for: .normal)
                self?.updateDoneButtonState()
            }
        }

        categoryButton.menu = UIMenu(title: "", options: .displayInline, children: actions)
        categoryButton.showsMenuAsPrimaryAction = true
    }

    private func setupTextFieldDelegates() {
        titleTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        updateDoneButtonState()
    }

    private func configureMediaCollectionView() {
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self
        mediaCollectionView.register(CommunityPostMediaAddCell.self, forCellWithReuseIdentifier: CommunityPostMediaAddCell.reuseIdentifier)
        mediaCollectionView.register(CommunityPostMediaPreviewCell.self, forCellWithReuseIdentifier: CommunityPostMediaPreviewCell.reuseIdentifier)
    }

    private func removeMediaItem(at index: Int) {
        guard index < mediaItems.count else { return }
        mediaItems.remove(at: index)
        mediaCollectionView.reloadData()
    }

    private func populateInitialDataIfNeeded() {
        guard let postToEdit = viewModel.postToEdit else { return }

        let category = Category.allCases.first { $0.title == postToEdit.category }
        selectedCategory = category
        if let category = category {
            categoryButton.setTitle(category.title, for: .normal)
            categoryButton.setTitleColor(AppColor.gray90, for: .normal)
        }

        titleTextField.text = postToEdit.title

        selectedStoreId = postToEdit.store.storeId
        selectedStoreName = postToEdit.store.name
        storeButton.setTitle(postToEdit.store.name, for: .normal)
        storeButton.setTitleColor(AppColor.gray90, for: .normal)

        contentTextView.text = postToEdit.content
        contentPlaceholderLabel.isHidden = !postToEdit.content.isEmpty

        updateDoneButtonState()
    }
}

extension CommunityPostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentPlaceholderLabel.isHidden = !textView.text.isEmpty
        updateDoneButtonState()
    }
}

extension CommunityPostViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mediaItems.count >= Layout.maxMediaCount {
            return mediaItems.count
        }
        return mediaItems.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mediaItems.count < Layout.maxMediaCount && indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommunityPostMediaAddCell.reuseIdentifier, for: indexPath) as! CommunityPostMediaAddCell
            cell.configure(currentCount: mediaItems.count, maxCount: Layout.maxMediaCount)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommunityPostMediaPreviewCell.reuseIdentifier, for: indexPath) as! CommunityPostMediaPreviewCell
        let mediaIndex = mediaItems.count < Layout.maxMediaCount ? indexPath.item - 1 : indexPath.item
        let item = mediaItems[mediaIndex]
        cell.configure(with: item)
        cell.onRemoveTapped = { [weak self] in
            self?.removeMediaItem(at: mediaIndex)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if mediaItems.count < Layout.maxMediaCount && indexPath.item == 0 {
            presentImagePicker()
        }
    }

    private func presentImagePicker() {
        let remaining = Layout.maxMediaCount - mediaItems.count
        guard remaining > 0 else { return }

        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = remaining
        config.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        Layout.mediaItemSize
    }
}

struct CommunityPostMediaItem: Hashable {
    let id = UUID()
    let kind: Kind

    enum Kind: Hashable {
        case image(UIImage)
        case video(thumbnail: UIImage, url: URL)
        case remote(url: String, thumbnailUrl: String?, isVideo: Bool)
    }
}

private final class CommunityPostMediaAddCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityPostMediaAddCell"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "camera.fill"))
        imageView.tintColor = AppColor.gray75
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray75
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppColor.gray15
        contentView.layer.cornerRadius = 8
        contentView.addSubview(iconImageView)
        contentView.addSubview(countLabel)

        iconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-8)
            $0.size.equalTo(24)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(currentCount: Int, maxCount: Int) {
        countLabel.text = "\(currentCount)/\(maxCount)"
    }
}

private final class CommunityPostMediaPreviewCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityPostMediaPreviewCell"

    var onRemoveTapped: (() -> Void)?

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        imageView.tintColor = AppColor.gray0
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColor.gray0
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        contentView.addSubview(playImageView)
        contentView.addSubview(removeButton)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        playImageView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(28) }
        removeButton.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(4); $0.size.equalTo(20) }

        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: CommunityPostMediaItem) {
        switch item.kind {
        case let .image(image):
            imageView.image = image
            playImageView.isHidden = true
        case let .video(thumbnail, url: _):
            imageView.image = thumbnail
            playImageView.isHidden = false
        case let .remote(url, thumbnailUrl, isVideo):
            playImageView.isHidden = !isVideo
            imageView.resetImage()
            if isVideo, let thumbUrl = thumbnailUrl {
                imageView.setImage(url: thumbUrl)
            } else {
                imageView.setImage(url: url)
            }
        }
    }

    @objc private func removeButtonTapped() {
        onRemoveTapped?()
    }
}

extension CommunityPostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let remaining = Layout.maxMediaCount - mediaItems.count
        guard remaining > 0 else { return }

        let limitedResults = Array(results.prefix(remaining))
        let group = DispatchGroup()
        var newItems: [(Int, CommunityPostMediaItem)] = []

        for (index, result) in limitedResults.enumerated() {
            let provider = result.itemProvider

            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                    guard let self = self, let url = url else {
                        group.leave()
                        return
                    }

                    guard let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 else {
                        group.leave()
                        return
                    }

                    let fileSizeMB = Double(fileSize) / 1_048_576
                    if fileSizeMB > 5.0 {
                        DispatchQueue.main.async {
                            self.showAlert(
                                title: "파일 용량 초과",
                                message: "동영상 파일 용량이 5MB를 초과했습니다.\n현재 용량: \(String(format: "%.1f", fileSizeMB))MB"
                            )
                            group.leave()
                        }
                        return
                    }

                    guard let savedFileName = FilePathManager.saveFile(at: url) else {
                        group.leave()
                        return
                    }

                    guard let localURL = FilePathManager.getFileURL(from: savedFileName) else {
                        group.leave()
                        return
                    }

                    let thumbnail = self.generateVideoThumbnail(url: localURL)
                    let item = CommunityPostMediaItem(
                        kind: .video(thumbnail: thumbnail ?? UIImage(), url: localURL)
                    )

                    DispatchQueue.main.async {
                        newItems.append((index, item))
                        group.leave()
                    }
                }
                continue
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    guard let self = self, let image = object as? UIImage else {
                        group.leave()
                        return
                    }

                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        group.leave()
                        return
                    }

                    let fileSizeMB = Double(imageData.count) / 1_048_576
                    if fileSizeMB > 5.0 {
                        DispatchQueue.main.async {
                            self.showAlert(
                                title: "파일 용량 초과",
                                message: "이미지 파일 용량이 5MB를 초과했습니다.\n현재 용량: \(String(format: "%.1f", fileSizeMB))MB"
                            )
                            group.leave()
                        }
                        return
                    }

                    let item = CommunityPostMediaItem(
                        kind: .image(image)
                    )
                    DispatchQueue.main.async {
                        newItems.append((index, item))
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            let sortedItems = newItems.sorted { $0.0 < $1.0 }.map { $0.1 }
            self?.mediaItems.append(contentsOf: sortedItems)
        }
    }

    private func generateVideoThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 800, height: 800)
        let time = CMTime(seconds: 0, preferredTimescale: 600)

        guard let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

private extension UITextField {
    func setLeftPadding(_ padding: CGFloat) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 1))
        leftView = view
        leftViewMode = .always
    }
}
