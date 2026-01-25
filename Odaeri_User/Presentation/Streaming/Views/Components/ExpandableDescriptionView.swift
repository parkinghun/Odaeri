//
//  ExpandableDescriptionView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/25/26.
//

import UIKit
import Combine

final class ExpandableDescriptionView: UIView {
    private var isExpanded: Bool = false
    private var cancellables = Set<AnyCancellable>()

    let toggleButtonTappedPublisher: AnyPublisher<Void, Never>

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("더보기", for: .normal)
        button.setTitleColor(AppColor.gray60, for: .normal)
        button.titleLabel?.font = AppFont.body3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        toggleButtonTappedPublisher = toggleButton.tapPublisher().eraseToAnyPublisher()

        super.init(frame: frame)
        setupViews()
        bindToggleButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(toggleButton)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func bindToggleButton() {
        toggleButtonTappedPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isExpanded.toggle()
                self.updateUI(isExpanded: self.isExpanded)
            }
            .store(in: &cancellables)
    }

    private func updateUI(isExpanded: Bool) {
        descriptionLabel.numberOfLines = isExpanded ? 0 : 2
        toggleButton.setTitle(isExpanded ? "접기" : "더보기", for: .normal)

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    func configure(text: String) {
        descriptionLabel.text = text

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.descriptionLabel.layoutIfNeeded()

            let isTruncated = self.descriptionLabel.isTruncated()
            self.toggleButton.isHidden = !isTruncated
        }
    }
}

private extension UILabel {
    func isTruncated() -> Bool {
        guard let text = text, !text.isEmpty else { return false }

        let size = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let textHeight = text.boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font as Any],
            context: nil
        ).height

        return textHeight > bounds.height
    }
}
