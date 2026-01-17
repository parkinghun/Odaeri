//
//  CommunityCommentInputView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import SnapKit

final class CommunityCommentInputView: UIView {
    enum Mode {
        case normal
        case reply(userName: String, commentId: String)
        case edit(commentId: String, originalContent: String)
    }

    var onSendTapped: ((String) -> Void)?
    var onCancelReply: (() -> Void)?

    private var currentMode: Mode = .normal

    private let replyContextBar: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.isHidden = true
        return view
    }()

    private let replyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray75
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = AppColor.gray75
        return button
    }()

    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = AppColor.gray30
        view.layer.cornerRadius = 16
        return view
    }()

    private let textView: UITextView = {
        let view = UITextView()
        view.font = AppFont.body2
        view.textColor = AppColor.gray90
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 16
        view.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        view.isScrollEnabled = false
        return view
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "댓글을 입력하세요..."
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        return label
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전송", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body2
        button.backgroundColor = AppColor.gray30
        button.layer.cornerRadius = 8
        button.isEnabled = false
        return button
    }()

    private lazy var inputContainerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, textView, sendButton])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .bottom
        return stackView
    }()

    private lazy var replyContextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [replyLabel, cancelButton])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [replyContextBar, inputContainerStackView])
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()

    private enum Layout {
        static let profileSize: CGFloat = 32
        static let sendButtonWidth: CGFloat = 44
        static let contextBarHeight: CGFloat = 40
        static let containerPadding: CGFloat = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        setupTextViewObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray0

        addSubview(mainStackView)
        mainStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Layout.containerPadding)
            $0.bottom.equalToSuperview().inset(Layout.containerPadding)
        }

        replyContextBar.addSubview(replyContextStackView)
        replyContextStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.containerPadding)
            $0.centerY.equalToSuperview()
        }

        replyContextBar.snp.makeConstraints {
            $0.height.equalTo(Layout.contextBarHeight)
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(Layout.profileSize)
        }

        sendButton.snp.makeConstraints {
            $0.width.equalTo(Layout.sendButtonWidth)
        }

        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(handleSendTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)
    }

    private func setupTextViewObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }

    func configure(profileImageUrl: String?) {
        profileImageView.setImage(url: profileImageUrl)
    }

    func setMode(_ mode: Mode) {
        currentMode = mode

        switch mode {
        case .normal:
            replyContextBar.isHidden = true
            textView.text = ""
            placeholderLabel.isHidden = false
            updateSendButton()

        case .reply(let userName, _):
            replyContextBar.isHidden = false
            replyLabel.text = "\(userName)님에게 답글 남기는 중"
            textView.text = ""
            placeholderLabel.isHidden = false
            updateSendButton()

        case .edit(_, let originalContent):
            replyContextBar.isHidden = false
            replyLabel.text = "댓글 수정 중"
            textView.text = originalContent
            placeholderLabel.isHidden = true
            updateSendButton()
        }

        textView.becomeFirstResponder()
    }

    func getCurrentMode() -> Mode {
        return currentMode
    }

    @objc private func textViewDidChange() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateSendButton()
    }

    private func updateSendButton() {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isValidInput = !trimmedText.isEmpty

        let shouldEnable: Bool
        switch currentMode {
        case .normal, .reply:
            shouldEnable = isValidInput
        case .edit(_, let originalContent):
            shouldEnable = isValidInput && trimmedText != originalContent
        }

        sendButton.isEnabled = shouldEnable
        sendButton.backgroundColor = shouldEnable ? AppColor.deepSprout : AppColor.gray30
    }

    @objc private func handleSendTapped() {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        onSendTapped?(trimmedText)

        textView.text = ""
        placeholderLabel.isHidden = false
        updateSendButton()
    }

    @objc private func handleCancelTapped() {
        currentMode = .normal
        replyContextBar.isHidden = true
        textView.text = ""
        placeholderLabel.isHidden = false
        updateSendButton()
        onCancelReply?()
    }

    override var intrinsicContentSize: CGSize {
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let contextBarHeight = replyContextBar.isHidden ? 0 : Layout.contextBarHeight
        let inputHeight = max(Layout.profileSize, textSize.height + 16)
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: contextBarHeight + inputHeight + Layout.containerPadding * 2
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
