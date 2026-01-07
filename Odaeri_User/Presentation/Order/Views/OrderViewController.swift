//
//  OrderViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class OrderViewController: BaseViewController<OrderViewModel> {
    weak var coordinator: OrderCoordinator?

    private let noticeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.brightSprout
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.deepSprout.cgColor
        view.layer.cornerRadius = 16
        return view
    }()

    private let noticeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.brandCaption1
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let emptyImageView: UIImageView = {
        let view = UIImageView()
        view.image = AppImage.sesac.withRenderingMode(.alwaysTemplate)
        view.tintColor = AppColor.brightSprout
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문 내역이 없습니다."
        label.font = AppFont.brandTitle1
        label.textColor = AppColor.brightSprout
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "건강한 픽업 생활의 시작, 오대리"
        label.font = AppFont.brandCaption1
        label.textColor = AppColor.brightSprout
        label.textAlignment = .center
        return label
    }()

    private lazy var emptyStateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [emptyImageView, emptyTitleLabel, emptySubtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = AppColor.gray0
    }
    
    override func setupUI() {
        super.setupUI()

        view.addSubview(noticeContainerView)
        noticeContainerView.addSubview(noticeLabel)
        view.addSubview(emptyStateStackView)

        noticeLabel.attributedText = makeNoticeText()

        noticeContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(AppSpacing.xSmall)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.height.equalTo(40)
        }

        noticeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        emptyImageView.snp.makeConstraints {
            $0.size.equalTo(62)
        }

        emptyStateStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func bind() {
        super.bind()

        let input = OrderViewModel.Input()
        let output = viewModel.transform(input: input)
    }

    private func makeNoticeText() -> NSAttributedString {
        let text = "픽업을 하실 때는 주문번호를 꼭 말씀해주세요!"
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: AppFont.brandCaption1,
                .foregroundColor: AppColor.deepSprout
            ]
        )

        let highlightWords = ["픽업", "주문번호"]
        for word in highlightWords {
            let range = (text as NSString).range(of: word)
            if range.location != NSNotFound {
                attributed.addAttribute(.foregroundColor, value: AppColor.blackSprout, range: range)
            }
        }

        return attributed
    }
}
