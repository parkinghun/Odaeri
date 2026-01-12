//
//  ChatInputView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import SnapKit
import Combine
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

final class ChatInputView: UIView {
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()

    private let rootStackView = UIStackView()
    private let containerStackView = UIStackView()
    private var attachments: [ChatInputAttachmentItem] = []
    private var attachmentsHeightConstraint: NSLayoutConstraint?
    private let attachmentsContainerView = UIScrollView()
    private let attachmentsStackView = UIStackView()
    private var attachmentItemViews: [ChatInputAttachmentItemView] = []
    private var attachmentSizeConstraints: [NSLayoutConstraint] = []
    private let attachmentsSpacerView = UIView()

    var onSendMessage: ((String, [ChatInputAttachmentItem]) -> Void)?
    var onAttachmentTapped: ((ChatInputAttachmentItem) -> Void)?

    weak var parentViewController: UIViewController?

    private enum Layout {
        static let minHeight: CGFloat = 36
        static let maxHeight: CGFloat = 100
        static let horizontalPadding: CGFloat = AppSpacing.medium
        static let verticalPadding: CGFloat = AppSpacing.small
        static let textViewInset = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        static let buttonSize: CGFloat = 36
        static let attachmentCellSize: CGFloat = 60
        static let attachmentSpacing: CGFloat = 8
        static let maxAttachments: Int = 5
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 2

        textView.font = AppFont.body2
        textView.textColor = AppColor.gray90
        textView.backgroundColor = AppColor.gray15
        textView.layer.cornerRadius = 18
        textView.layer.cornerCurve = .continuous
        textView.textContainerInset = Layout.textViewInset
        textView.isScrollEnabled = false
        textView.delegate = self

        placeholderLabel.text = "메시지를 입력하세요"
        placeholderLabel.font = AppFont.body2
        placeholderLabel.textColor = AppColor.gray60

        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = AppColor.blackSprout
        sendButton.isEnabled = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = AppColor.gray75

        rootStackView.axis = .vertical
        rootStackView.alignment = .fill
        rootStackView.spacing = AppSpacing.small

        containerStackView.axis = .horizontal
        containerStackView.alignment = .bottom
        containerStackView.spacing = AppSpacing.small
        containerStackView.distribution = .fill

        attachmentsStackView.axis = .horizontal
        attachmentsStackView.alignment = .center
        attachmentsStackView.spacing = Layout.attachmentSpacing
        attachmentsStackView.distribution = .fill

        addSubview(rootStackView)

        rootStackView.addArrangedSubview(attachmentsContainerView)
        rootStackView.addArrangedSubview(containerStackView)

        attachmentsContainerView.addSubview(attachmentsStackView)
        attachmentsContainerView.showsHorizontalScrollIndicator = false
        attachmentsContainerView.alwaysBounceHorizontal = true
        attachmentsContainerView.alwaysBounceVertical = false
        attachmentsStackView.addArrangedSubview(attachmentsSpacerView)

        attachmentsSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        attachmentsSpacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        containerStackView.addArrangedSubview(addButton)
        containerStackView.addArrangedSubview(textView)
        containerStackView.addArrangedSubview(sendButton)

        textView.addSubview(placeholderLabel)
    }

    private func setupConstraints() {
        rootStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.verticalPadding)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            $0.bottom.equalToSuperview().inset(Layout.verticalPadding)
        }

        attachmentsHeightConstraint = attachmentsContainerView.heightAnchor.constraint(equalToConstant: 0)
        attachmentsHeightConstraint?.isActive = true

        attachmentsStackView.snp.makeConstraints {
            $0.edges.equalTo(attachmentsContainerView.contentLayoutGuide)
            $0.height.equalTo(attachmentsContainerView.frameLayoutGuide)
        }

        textView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(Layout.minHeight)
            $0.height.lessThanOrEqualTo(Layout.maxHeight)
        }

        addButton.snp.makeConstraints {
            $0.size.equalTo(Layout.buttonSize)
        }

        sendButton.snp.makeConstraints {
            $0.size.equalTo(Layout.buttonSize)
        }

        placeholderLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.textViewInset.left + 5)
            $0.top.equalToSuperview().offset(Layout.textViewInset.top)
        }

        updateAttachmentsUI()
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(handleSendButtonTap), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(handleAddButtonTap), for: .touchUpInside)
    }

    @objc private func handleSendButtonTap() {
        let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentAttachments = attachments
        guard !message.isEmpty || !currentAttachments.isEmpty else { return }

        onSendMessage?(message, currentAttachments)
        clearInput()
        clearAttachments()
    }

    private func clearInput() {
        textView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        textView.isScrollEnabled = false
    }

    private func clearAttachments() {
        attachments.removeAll()
        updateAttachmentsUI()
    }

    private func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateSendButtonState() {
        let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldEnable = !message.isEmpty || !attachments.isEmpty
        sendButton.isEnabled = shouldEnable
        sendButton.alpha = shouldEnable ? 1.0 : 0.5
    }

    @objc private func handleAddButtonTap() {
        guard let parentViewController = parentViewController else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "사진/동영상", style: .default) { [weak self] _ in
            self?.presentPhotoPicker(from: parentViewController)
        })
        alert.addAction(UIAlertAction(title: "파일", style: .default) { [weak self] _ in
            self?.presentDocumentPicker(from: parentViewController)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = addButton
            popover.sourceRect = addButton.bounds
        }

        parentViewController.present(alert, animated: true)
    }

    private func presentPhotoPicker(from viewController: UIViewController) {
        let remaining = Layout.maxAttachments - attachments.count
        guard remaining > 0 else { return }

        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = remaining
        config.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    private func presentDocumentPicker(from viewController: UIViewController) {
        let remaining = Layout.maxAttachments - attachments.count
        guard remaining > 0 else { return }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    private func appendAttachments(_ items: [ChatInputAttachmentItem]) {
        guard !items.isEmpty else { return }
        let remaining = Layout.maxAttachments - attachments.count
        let toAdd = items.prefix(remaining)
        attachments.append(contentsOf: toAdd)
        updateAttachmentsUI()
    }

    private func removeAttachment(at index: Int) {
        guard attachments.indices.contains(index) else { return }
        attachments.remove(at: index)
        updateAttachmentsUI()
    }

    private func updateAttachmentsUI() {
        attachmentsContainerView.isHidden = attachments.isEmpty
        attachmentItemViews.forEach { $0.removeFromSuperview() }
        attachmentsStackView.arrangedSubviews.forEach {
            if $0 === attachmentsSpacerView { return }
            attachmentsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        attachmentItemViews.removeAll()

        attachments.forEach { item in
            let itemView = ChatInputAttachmentItemView()
            itemView.configure(with: item)
            itemView.onRemove = { [weak self] in
                guard let self = self else { return }
                if let index = self.attachmentItemViews.firstIndex(where: { $0 === itemView }) {
                    self.removeAttachment(at: index)
                }
            }
            itemView.onTap = { [weak self] in
                self?.handleAttachmentTap(item)
            }
            attachmentsStackView.insertArrangedSubview(itemView, at: max(0, attachmentsStackView.arrangedSubviews.count - 1))
            attachmentItemViews.append(itemView)
        }

        updateAttachmentItemSizes()
        updateSendButtonState()
    }

    private func updateAttachmentItemSizes() {
        attachmentSizeConstraints.forEach { $0.isActive = false }
        attachmentSizeConstraints.removeAll()

        let count = attachmentItemViews.count
        guard count > 0 else {
            attachmentsHeightConstraint?.constant = 0
            return
        }

        layoutIfNeeded()

        let availableWidth = attachmentsContainerView.bounds.width > 0
            ? attachmentsContainerView.bounds.width
            : UIScreen.main.bounds.width - (Layout.horizontalPadding * 2)

        let totalSpacing = Layout.attachmentSpacing * CGFloat(max(0, count - 1))
        let maxItemWidth = (availableWidth - totalSpacing) / CGFloat(count)
        let itemSize = max(36, min(Layout.attachmentCellSize, maxItemWidth))

        attachmentItemViews.forEach { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: itemSize)
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: itemSize)
            widthConstraint.isActive = true
            heightConstraint.isActive = true
            attachmentSizeConstraints.append(contentsOf: [widthConstraint, heightConstraint])
        }

        attachmentsHeightConstraint?.constant = itemSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !attachments.isEmpty {
            updateAttachmentItemSizes()
        }
    }

    private func handleAttachmentTap(_ item: ChatInputAttachmentItem) {
        guard let parentViewController = parentViewController else { return }
        switch item {
        case .video(let url, _, _):
            AppMediaService.shared.playVideo(url: url.absoluteString, from: parentViewController)
        case .file(let url, let fileName, _, _):
            AppMediaService.shared.previewFile(url: url.absoluteString, fileName: fileName, from: parentViewController)
        case .image:
            onAttachmentTapped?(item)
        }
    }

    private func presentVideoTranscodeFailureAlert() {
        guard let parentViewController = parentViewController else { return }
        let alert = UIAlertController(
            title: "영상 처리 실패",
            message: "영상 처리에 실패했습니다. 다시 선택해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        parentViewController.present(alert, animated: true)
    }

    private func copyToTemporaryDirectory(from url: URL, fileName: String? = nil) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ChatUploads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.createDirectory(
                at: tempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let originalFileName = fileName ?? url.lastPathComponent
        let safeFileName = originalFileName.isEmpty ? "\(UUID().uuidString)" : originalFileName
        var destinationURL = tempDirectory.appendingPathComponent(safeFileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            destinationURL = tempDirectory.appendingPathComponent("\(UUID().uuidString)_\(safeFileName)")
        }

        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    private func writeImageToTemporaryDirectory(_ image: UIImage) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ChatUploads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.createDirectory(
                at: tempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let fileName = "image_\(UUID().uuidString).jpg"
        let destinationURL = tempDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        do {
            try data.write(to: destinationURL)
            return destinationURL
        } catch {
            return nil
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

    private func transcodeVideo(
        at url: URL,
        completion: @escaping (URL?) -> Void
    ) {
        let asset = AVAsset(url: url)
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1280x720
        ) else {
            completion(nil)
            return
        }

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ChatUploads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.createDirectory(
                at: tempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let outputURL = tempDirectory.appendingPathComponent("video_\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        exportSession.outputURL = outputURL
        if exportSession.supportedFileTypes.contains(.mp4) {
            exportSession.outputFileType = .mp4
        } else {
            completion(nil)
            return
        }
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(outputURL)
                default:
                    completion(nil)
                }
            }
        }
    }
}

extension ChatInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateSendButtonState()

        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        textView.isScrollEnabled = estimatedSize.height > Layout.maxHeight
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            handleSendButtonTap()
            return false
        }
        return true
    }
}

extension ChatInputView: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let remaining = Layout.maxAttachments - attachments.count
        guard remaining > 0 else { return }

        let limitedResults = Array(results.prefix(remaining))
        let group = DispatchGroup()
        var newItems: [(Int, ChatInputAttachmentItem)] = []

        for (index, result) in limitedResults.enumerated() {
            let provider = result.itemProvider

            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                    guard let self = self, let url = url else {
                        group.leave()
                        return
                    }
                    guard let localURL = self.copyToTemporaryDirectory(from: url) else {
                        group.leave()
                        return
                    }

                    self.transcodeVideo(at: localURL) { [weak self] transcodedURL in
                        guard let self = self else {
                            group.leave()
                            return
                        }
                        guard let transcodedURL = transcodedURL else {
                            DispatchQueue.main.async {
                                self.presentVideoTranscodeFailureAlert()
                                group.leave()
                            }
                            return
                        }

                        let thumbnail = self.generateVideoThumbnail(url: transcodedURL)
                        let item = ChatInputAttachmentItem.video(
                            transcodedURL,
                            thumbnail: thumbnail,
                            id: UUID().uuidString
                        )

                        DispatchQueue.main.async {
                            newItems.append((index, item))
                            group.leave()
                        }
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

                    let fileURL = self.writeImageToTemporaryDirectory(image)
                    let item = ChatInputAttachmentItem.image(
                        image,
                        fileURL: fileURL,
                        id: UUID().uuidString
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
            self?.appendAttachments(sortedItems)
        }
    }
}

extension ChatInputView: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard !urls.isEmpty else { return }

        let remaining = Layout.maxAttachments - attachments.count
        guard remaining > 0 else { return }

        var newItems: [ChatInputAttachmentItem] = []

        for url in urls.prefix(remaining) {
            let shouldStop = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStop {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let originalFileName = url.lastPathComponent
            guard let localURL = copyToTemporaryDirectory(from: url, fileName: originalFileName) else { continue }

            let fileName = originalFileName.isEmpty ? localURL.lastPathComponent : originalFileName
            let fileType = ChatInputAttachmentItem.FileType.from(url: localURL)
            let item = ChatInputAttachmentItem.file(
                localURL,
                fileName: fileName,
                fileType: fileType,
                id: UUID().uuidString
            )
            newItems.append(item)
        }

        appendAttachments(newItems)
    }
}
