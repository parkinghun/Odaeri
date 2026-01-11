//
//  ChatInputView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import SnapKit
import Combine

final class ChatInputView: UIView {
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()

    private let containerStackView = UIStackView()

    var onSendMessage: ((String) -> Void)?

    private enum Layout {
        static let minHeight: CGFloat = 36
        static let maxHeight: CGFloat = 100
        static let horizontalPadding: CGFloat = AppSpacing.medium
        static let verticalPadding: CGFloat = AppSpacing.small
        static let textViewInset = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        static let buttonSize: CGFloat = 36
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

        containerStackView.axis = .horizontal
        containerStackView.alignment = .bottom
        containerStackView.spacing = AppSpacing.small
        containerStackView.distribution = .fill

        addSubview(containerStackView)

        containerStackView.addArrangedSubview(textView)
        containerStackView.addArrangedSubview(sendButton)

        textView.addSubview(placeholderLabel)
    }

    private func setupConstraints() {
        containerStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.verticalPadding)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            $0.bottom.equalToSuperview().inset(Layout.verticalPadding)
        }

        textView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(Layout.minHeight)
            $0.height.lessThanOrEqualTo(Layout.maxHeight)
        }

        sendButton.snp.makeConstraints {
            $0.size.equalTo(Layout.buttonSize)
        }

        placeholderLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.textViewInset.left + 5)
            $0.top.equalToSuperview().offset(Layout.textViewInset.top)
        }
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(handleSendButtonTap), for: .touchUpInside)
    }

    @objc private func handleSendButtonTap() {
        let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        onSendMessage?(message)
        clearInput()
    }

    private func clearInput() {
        textView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        textView.isScrollEnabled = false
    }

    private func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateSendButtonState() {
        let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isEnabled = !message.isEmpty
        sendButton.alpha = message.isEmpty ? 0.5 : 1.0
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
