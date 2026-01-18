//
//  ReviewGallerySegmentedControl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/19/26.
//

import UIKit
import SnapKit

final class ReviewGallerySegmentedControl: UIView {
    private enum Layout {
        static let indicatorHeight: CGFloat = 2
    }

    private let imageButton = ReviewGallerySegmentButton(title: "이미지")
    private let videoButton = ReviewGallerySegmentButton(title: "동영상")
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.deepSprout
        view.layer.cornerRadius = Layout.indicatorHeight / 2
        return view
    }()

    private var indicatorLeadingConstraint: Constraint?
    private var selectedIndex = 0
    var onSelectionChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateSelection(index: 0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [imageButton, videoButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = AppSpacing.small

        addSubview(stackView)
        addSubview(indicatorView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        indicatorView.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.height.equalTo(Layout.indicatorHeight)
            $0.width.equalToSuperview().multipliedBy(0.5)
            indicatorLeadingConstraint = $0.leading.equalToSuperview().constraint
        }

        imageButton.addTarget(self, action: #selector(handleImageTapped), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(handleVideoTapped), for: .touchUpInside)
    }

    @objc private func handleImageTapped() {
        updateSelection(index: 0, animated: true)
        onSelectionChanged?(0)
    }

    @objc private func handleVideoTapped() {
        updateSelection(index: 1, animated: true)
        onSelectionChanged?(1)
    }

    private func updateSelection(index: Int, animated: Bool) {
        selectedIndex = index
        imageButton.isSelected = index == 0
        videoButton.isSelected = index == 1

        let targetLeading = bounds.width * (index == 0 ? 0 : 0.5)
        let update = {
            self.indicatorLeadingConstraint?.update(offset: targetLeading)
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: update)
        } else {
            update()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let targetLeading = bounds.width * (selectedIndex == 0 ? 0 : 0.5)
        indicatorLeadingConstraint?.update(offset: targetLeading)
    }
}

private final class ReviewGallerySegmentButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(AppColor.gray60, for: .normal)
        setTitleColor(AppColor.gray90, for: .selected)
        titleLabel?.font = AppFont.body2Bold
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
