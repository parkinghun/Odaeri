//
//  UIBezierPath+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 12/31/25.
//

import UIKit

extension UIBezierPath {
    static func shopImageMaskPath(
        in bounds: CGRect,
        mainRadius: CGFloat = 20,    // 파이는 원의 반지름
        smoothRadius: CGFloat = 8,   // 이음새 부드러움 (Reverse Corner)
        normalRadius: CGFloat = 16   // 나머지 일반 모서리
    ) -> UIBezierPath {
        let path = UIBezierPath()
        let w = bounds.width
        let h = bounds.height
        
        // 핵심 축 (Pivot): 파인 원과 연결 곡선이 만나는 기준점
        let pivot: CGFloat = mainRadius + smoothRadius

        // 1. 좌측 하단에서 시작 (이미지 전체 영역 확보 시작)
        path.move(to: CGPoint(x: 0, y: h))
        
        // 2. 좌측 라인을 타고 올라가다 아래쪽 볼록 곡선 시작점으로 이동
        path.addLine(to: CGPoint(x: 0, y: pivot))
        
        // 3. [아래쪽 연결부] 밖으로 볼록 (Clockwise: true)
        path.addArc(withCenter: CGPoint(x: smoothRadius, y: pivot),
                    radius: smoothRadius,
                    startAngle: .pi,
                    endAngle: .pi * 1.5,
                    clockwise: true)
        
        // 4. [메인 파임] 안으로 오목 (Clockwise: false)
        // 중심을 (pivot, pivot)으로 설정해야 좌측 상단 끝 모서리(0,0)를 기준으로 파입니다.
        path.addArc(withCenter: CGPoint(x: pivot, y: pivot),
                    radius: mainRadius,
                    startAngle: .pi * 1.5,
                    endAngle: .pi,
                    clockwise: false)
        
        // 5. [오른쪽 연결부] 밖으로 볼록 (Clockwise: true)
        path.addArc(withCenter: CGPoint(x: pivot, y: smoothRadius),
                    radius: smoothRadius,
                    startAngle: .pi * 0.5,
                    endAngle: 0,
                    clockwise: true)

        // 6. 상단 라인 연결 및 우측 상단 일반 모서리
        path.addLine(to: CGPoint(x: w - normalRadius, y: 0))
        path.addArc(withCenter: CGPoint(x: w - normalRadius, y: normalRadius),
                    radius: normalRadius,
                    startAngle: -.pi/2,
                    endAngle: 0,
                    clockwise: true)
        
        // 7. 우측 하단 및 좌측 하단까지 경로를 완전히 닫음 (매우 중요)
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.close()
        
        return path
    }
}
