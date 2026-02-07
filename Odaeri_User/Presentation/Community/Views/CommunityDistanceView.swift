//
//  CommunityDistanceView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/8/26.
//

import UIKit
import SnapKit

final class CommunityDistanceView: UIView {
    var onIndexSelected: ((Int) -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.gray45.cgColor
        view.backgroundColor = AppColor.gray15
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let labelContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.brightSprout2
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.deepSprout.cgColor
        view.layer.cornerRadius = 4
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Distance"
        label.font = AppFont.body3Bold
        label.textColor = AppColor.blackSprout
        return label
    }()

    private let barStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.blackSprout
        view.layer.cornerRadius = 9
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption2SemiBold
        label.textColor = AppColor.gray0
        return label
    }()

    private var barViews: [UIView] = []
    private var selectedIndex: Int = 0
    private var badgeCenterXConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupBars()
        setupGestures()
        updateBars(for: selectedIndex)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(badgeView)
        addSubview(containerView)
        containerView.addSubview(labelContainerView)
        labelContainerView.addSubview(label)
        containerView.addSubview(barStackView)
        badgeView.addSubview(badgeLabel)
        bringSubviewToFront(badgeView)

        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(badgeView.snp.bottom).offset(AppSpacing.xSmall)
            $0.height.equalTo(40)
        }

        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.height.equalTo(18)
        }

        labelContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(AppSpacing.medium)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
        }

        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        barStackView.snp.makeConstraints {
            $0.leading.equalTo(labelContainerView.snp.trailing).offset(AppSpacing.medium)
            $0.trailing.equalToSuperview().inset(AppSpacing.medium)
            $0.centerY.equalTo(labelContainerView)
        }

        badgeLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.small)
        }
        
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        labelContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupBars() {
        barViews = (0..<16).map { _ in
            let view = UIView()
            view.layer.cornerRadius = 4
            view.backgroundColor = AppColor.gray30
            view.snp.makeConstraints {
                $0.width.equalTo(8)
                $0.height.equalTo(20)
            }
            barStackView.addArrangedSubview(view)
            return view
        }
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        barStackView.addGestureRecognizer(tap)
        barStackView.addGestureRecognizer(pan)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: barStackView)
        handleSelectionChange(index: indexForLocation(location))
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: barStackView)
        handleSelectionChange(index: indexForLocation(location))
    }

    private func indexForLocation(_ location: CGPoint) -> Int {
        guard !barViews.isEmpty else { return 0 }
        let distances = barViews.enumerated().map { index, view -> (Int, CGFloat) in
            let centerX = view.frame.midX
            return (index, abs(centerX - location.x))
        }
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? 0
    }

    private func handleSelectionChange(index: Int) {
        let clampedIndex = max(0, min(index, barViews.count - 1))
        guard clampedIndex != selectedIndex else { return }
        selectedIndex = clampedIndex
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onIndexSelected?(clampedIndex)
    }

    private func updateBadgePosition() {
        badgeCenterXConstraint?.deactivate()
        guard barViews.indices.contains(selectedIndex) else { return }
        badgeCenterXConstraint = badgeView.snp.prepareConstraints {
            $0.centerX.equalTo(barViews[selectedIndex])
        }.first
        badgeCenterXConstraint?.activate()
        layoutIfNeeded()
    }

    func apply(selection: CommunityDistanceSelection) {
        let clampedIndex = max(0, min(selection.index, barViews.count - 1))
        selectedIndex = clampedIndex
        badgeLabel.text = selection.label
        updateBars(for: clampedIndex)
        updateBadgePosition()
    }

    private func updateBars(for index: Int) {
        for (idx, view) in barViews.enumerated() {
            if idx <= index {
                view.backgroundColor = idx < 8 ? AppColor.deepSprout : AppColor.blackSprout
            } else {
                view.backgroundColor = AppColor.gray30
            }
        }
    }
}
