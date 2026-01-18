//
//  ReviewWriteViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import UIKit
import Combine
import SnapKit
import PhotosUI

final class ReviewWriteViewController: BaseViewController<ReviewWriteViewModel> {
    private enum Constant {
        static let horizontalInset: CGFloat = AppSpacing.screenMargin
        static let contentMinLength = 10
        static let contentMaxLength = 500
        static let ratingCount = 5
        static let mediaItemSize: CGFloat = 88
        static let mediaItemSpacing: CGFloat = 12
        static let mediaSectionHeight: CGFloat = 108
        static let maxImageCount = 5
        static let submitButtonHeight: CGFloat = 50
    }

    private let ratingSubject: CurrentValueSubject<Int, Never>
    private let contentSubject = CurrentValueSubject<String, Never>("")
    private let submitSubject = PassthroughSubject<Void, Never>()

    private var selectedImages: [UIImage] = [] {
        didSet {
            mediaCollectionView.reloadData()
        }
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerView = ReviewWriteHeaderView()

    private let ratingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.text = "별점"
        return label
    }()

    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xxSmall
        stackView.alignment = .center
        return stackView
    }()

    private let contentTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.text = "리뷰 내용"
        return label
    }()

    private let contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = AppFont.body2
        textView.textColor = AppColor.gray90
        textView.backgroundColor = AppColor.gray15
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    private let contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.text = "리뷰 내용을 작성해주세요"
        return label
    }()

    private let contentGuideLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.text = "최소 10자 이상 작성해 주세요"
        return label
    }()

    private let contentCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.textAlignment = .right
        label.text = "0 / 500"
        return label
    }()

    private let mediaTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        label.text = "사진 첨부"
        return label
    }()

    private lazy var mediaCollectionView: UICollectionView = {
        let layout = createMediaLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ReviewWriteImageAddCell.self, forCellWithReuseIdentifier: ReviewWriteImageAddCell.reuseIdentifier)
        collectionView.register(ReviewWriteImageCell.self, forCellWithReuseIdentifier: ReviewWriteImageCell.reuseIdentifier)
        return collectionView
    }()

    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = AppFont.body1Bold
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.setTitleColor(AppColor.gray60, for: .disabled)
        button.backgroundColor = AppColor.deepSprout
        return button
    }()

    private var ratingButtons: [UIButton] = []

    override init(viewModel: ReviewWriteViewModel) {
        self.ratingSubject = CurrentValueSubject<Int, Never>(viewModel.mode.initialRating)
        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateRatingButtons(rating: viewModel.mode.initialRating)
        updateContentCounter(text: contentTextView.text)
        updateSubmitButton(isEnabled: false)
    }

    override func setupUI() {
        super.setupUI()

        navigationItem.title = viewModel.mode.navigationTitle

        view.backgroundColor = AppColor.gray0

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        contentView.addSubview(ratingTitleLabel)
        contentView.addSubview(ratingStackView)
        contentView.addSubview(contentTitleLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(contentGuideLabel)
        contentView.addSubview(contentCountLabel)
        contentView.addSubview(mediaTitleLabel)
        contentView.addSubview(mediaCollectionView)
        contentView.addSubview(submitButton)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(Constant.horizontalInset)
        }

        ratingTitleLabel.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(AppSpacing.large)
            $0.leading.equalToSuperview().inset(Constant.horizontalInset)
        }

        ratingStackView.snp.makeConstraints {
            $0.centerY.equalTo(ratingTitleLabel)
            $0.leading.equalTo(ratingTitleLabel.snp.trailing).offset(AppSpacing.medium)
        }

        contentTitleLabel.snp.makeConstraints {
            $0.top.equalTo(ratingStackView.snp.bottom).offset(AppSpacing.large)
            $0.leading.equalToSuperview().inset(Constant.horizontalInset)
        }

        contentTextView.snp.makeConstraints {
            $0.top.equalTo(contentTitleLabel.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.equalToSuperview().inset(Constant.horizontalInset)
            $0.height.equalTo(200)
        }

        contentGuideLabel.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(AppSpacing.xxSmall)
            $0.leading.equalTo(contentTextView)
        }

        contentCountLabel.snp.makeConstraints {
            $0.centerY.equalTo(contentGuideLabel)
            $0.trailing.equalTo(contentTextView)
        }

        mediaTitleLabel.snp.makeConstraints {
            $0.top.equalTo(contentGuideLabel.snp.bottom).offset(AppSpacing.large)
            $0.leading.equalToSuperview().inset(Constant.horizontalInset)
        }

        mediaCollectionView.snp.makeConstraints {
            $0.top.equalTo(mediaTitleLabel.snp.bottom).offset(AppSpacing.small)
            $0.leading.trailing.equalToSuperview().inset(Constant.horizontalInset)
            $0.height.equalTo(Constant.mediaSectionHeight)
        }

        submitButton.snp.makeConstraints {
            $0.top.equalTo(mediaCollectionView.snp.bottom).offset(AppSpacing.large)
            $0.leading.trailing.equalToSuperview().inset(Constant.horizontalInset)
            $0.height.equalTo(Constant.submitButtonHeight)
            $0.bottom.equalToSuperview().offset(-AppSpacing.large)
        }

        contentTextView.addSubview(contentPlaceholderLabel)
        contentPlaceholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalToSuperview().offset(14)
        }

        contentTextView.delegate = self
        submitButton.setTitle(viewModel.mode.actionTitle, for: .normal)
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)

        setupRatingButtons()
    }

    override func bind() {
        super.bind()

        let input = ReviewWriteViewModel.Input(
            ratingSelected: ratingSubject.eraseToAnyPublisher(),
            contentChanged: contentSubject.eraseToAnyPublisher(),
            submitTapped: submitSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.header
            .receive(on: DispatchQueue.main)
            .sink { [weak self] header in
                self?.headerView.configure(with: header)
            }
            .store(in: &cancellables)

        output.currentRating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rating in
                self?.updateRatingButtons(rating: rating)
            }
            .store(in: &cancellables)

        output.isSubmitEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.updateSubmitButton(isEnabled: isEnabled)
            }
            .store(in: &cancellables)
    }

    private func setupRatingButtons() {
        ratingButtons = (0..<Constant.ratingCount).map { index in
            let button = UIButton(type: .system)
            button.tag = index + 1
            button.setImage(AppImage.starEmpty, for: .normal)
            button.addTarget(self, action: #selector(handleRatingTapped(_:)), for: .touchUpInside)
            button.tintColor = AppColor.gray45
            return button
        }

        ratingButtons.forEach { ratingStackView.addArrangedSubview($0) }
    }

    private func updateRatingButtons(rating: Int) {
        for (index, button) in ratingButtons.enumerated() {
            let isSelected = index < rating
            button.setImage(isSelected ? AppImage.starFill : AppImage.starEmpty, for: .normal)
            button.tintColor = isSelected ? AppColor.brightForsythia : AppColor.gray45
        }
    }

    private func updateSubmitButton(isEnabled: Bool) {
        submitButton.isEnabled = isEnabled
        submitButton.backgroundColor = isEnabled ? AppColor.deepSprout : AppColor.gray45
    }

    private func updateContentCounter(text: String?) {
        let length = text?.count ?? 0
        contentCountLabel.text = "\(length) / \(Constant.contentMaxLength)"
        let shouldHighlight = length >= Constant.contentMinLength
        contentGuideLabel.textColor = shouldHighlight ? AppColor.deepSprout : AppColor.gray60
    }

    @objc private func handleRatingTapped(_ sender: UIButton) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        ratingSubject.send(sender.tag)
    }

    @objc private func handleSubmit() {
        submitSubject.send(())
    }

    private func presentImagePicker() {
        guard selectedImages.count < Constant.maxImageCount else { return }
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = Constant.maxImageCount - selectedImages.count
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func createMediaLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Constant.mediaItemSize),
            heightDimension: .absolute(Constant.mediaItemSize)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Constant.mediaItemSize),
            heightDimension: .absolute(Constant.mediaItemSize)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Constant.mediaItemSpacing

        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension ReviewWriteViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        contentPlaceholderLabel.isHidden = !text.isEmpty
        updateContentCounter(text: text)
        contentSubject.send(text)
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= Constant.contentMaxLength
    }
}

extension ReviewWriteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count + 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReviewWriteImageAddCell.reuseIdentifier,
                for: indexPath
            ) as! ReviewWriteImageAddCell
            cell.configure(currentCount: selectedImages.count, maxCount: Constant.maxImageCount)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ReviewWriteImageCell.reuseIdentifier,
            for: indexPath
        ) as! ReviewWriteImageCell
        let image = selectedImages[indexPath.item - 1]
        cell.configure(image: image)
        cell.onDeleteTapped = { [weak self] in
            self?.selectedImages.remove(at: indexPath.item - 1)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            presentImagePicker()
        }
    }
}

extension ReviewWriteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let providers = results.map { $0.itemProvider }
        let availableSlots = Constant.maxImageCount - selectedImages.count
        let limitedProviders = providers.prefix(availableSlots)

        limitedProviders.forEach { provider in
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    guard let self, let image = object as? UIImage else { return }
                    DispatchQueue.main.async {
                        self.selectedImages.append(image)
                    }
                }
            }
        }
    }
}

private final class ReviewWriteHeaderView: UIView {
    private enum Layout {
        static let imageSize: CGFloat = 52
    }

    private let storeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        return view
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1Bold
        label.textColor = AppColor.gray90
        return label
    }()

    private let menuChipLabel = ReviewWriteChipLabel()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeNameLabel, menuChipLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xxSmall
        return stackView
    }()

    private lazy var rootStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [storeImageView, textStackView])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.medium
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(rootStackView)
        rootStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        storeImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.imageSize)
        }
    }

    func configure(with header: ReviewWriteHeader) {
        storeNameLabel.text = header.storeName
        menuChipLabel.text = header.menuSummary
        storeImageView.setImage(url: header.storeImageUrl)
    }
}

private final class ReviewWriteChipLabel: UILabel {
    private let contentInset = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = AppFont.caption1
        textColor = AppColor.gray75
        backgroundColor = AppColor.gray15
        layer.cornerRadius = 10
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }
}

private final class ReviewWriteImageAddCell: UICollectionViewCell {
    static let reuseIdentifier = "ReviewWriteImageAddCell"

    private let iconView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "plus"))
        view.tintColor = AppColor.gray60
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppColor.gray30.cgColor

        contentView.addSubview(iconView)
        contentView.addSubview(countLabel)

        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(22)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
    }

    func configure(currentCount: Int, maxCount: Int) {
        countLabel.text = "\(currentCount)/\(maxCount)"
    }
}

private final class ReviewWriteImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ReviewWriteImageCell"

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColor.gray0
        return button
    }()

    var onDeleteTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(removeButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        removeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
            $0.size.equalTo(22)
        }

        removeButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    }

    func configure(image: UIImage) {
        imageView.image = image
    }

    @objc private func handleDelete() {
        onDeleteTapped?()
    }
}
