//
//  StepProgressBar.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import SwiftUI

struct StepProgressBar: View {
    let currentStep: Int

    private let steps = ["접수", "승인", "조리", "대기", "완료"]
    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                GeometryReader { geometry in
                    let stepWidth = geometry.size.width / CGFloat(totalSteps - 1)

                    Path { path in
                        let y = geometry.size.height / 2
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                    Path { path in
                        let y = geometry.size.height / 2
                        let progressWidth = stepWidth * CGFloat(currentStep - 1)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: min(progressWidth, geometry.size.width), y: y))
                    }
                    .stroke(Color.blackSprout, lineWidth: 2)

                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index < currentStep ? Color.blackSprout : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .position(x: stepWidth * CGFloat(index), y: geometry.size.height / 2)
                    }
                }
                .frame(height: 20)
            }

            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Text(steps[index])
                        .font(.system(size: 10, weight: index < currentStep ? .bold : .regular))
                        .foregroundColor(index < currentStep ? .blackSprout : .gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct StepProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            StepProgressBar(currentStep: 1)
            StepProgressBar(currentStep: 2)
            StepProgressBar(currentStep: 3)
            StepProgressBar(currentStep: 4)
            StepProgressBar(currentStep: 5)
        }
        .padding()
    }
}
