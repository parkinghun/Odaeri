//
//  PickchelinView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 2/7/26.
//

import UIKit
import SnapKit

class PickchelinTagView: UIView {
    enum Style {
        case list
        case detail
    }
    
    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    private let label = UILabel()
    private let shapeLayer = CAShapeLayer()
    private let style: Style
    
    init(style: Style = .list) {
        self.style = style
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.style = .list
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        iconImageView.image = AppImage.pickFill
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppColor.gray15
        
        label.text = "픽슐랭"
        label.font = style == .detail ? AppFont.caption1 : AppFont.caption2
        label.textColor = AppColor.gray15
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = AppSpacing.xSmall
        
        addSubview(stackView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(label)
        
        shapeLayer.fillColor = AppColor.blackSprout.cgColor
        shapeLayer.strokeColor = AppColor.brightSprout.cgColor
        shapeLayer.lineWidth = 1
        layer.insertSublayer(shapeLayer, at: 0)
        
        stackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(AppSpacing.xSmall)
            make.leading.equalToSuperview().offset(style == .detail ? AppSpacing.smallMedium : AppSpacing.semiSmall)
            make.trailing.equalToSuperview().inset(AppSpacing.medium)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(style == .detail ? 16 : 12)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawPath()
    }
    
    private func drawPath() {
        let path = UIBezierPath()
        let w = bounds.width
        let h = bounds.height
        let r = h / 2
        
        // 왼쪽 반원
        path.move(to: CGPoint(x: r, y: 0))
        path.addArc(withCenter: CGPoint(x: r, y: r), radius: r,
                    startAngle: -.pi/2, endAngle: .pi/2, clockwise: false)
        
        // 하단 직선
        path.addLine(to: CGPoint(x: w, y: h))
        
        // 오른쪽 파인 홈
        path.addLine(to: CGPoint(x: w - 8, y: h / 2))
        path.addLine(to: CGPoint(x: w, y: 0))
        
        path.close()
        shapeLayer.path = path.cgPath
    }
}
