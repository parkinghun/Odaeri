//
//  AppColor+SwiftUI.swift
//  Odaeri
//
//  Created by 박성훈 on 01/19/26.
//

import SwiftUI

extension Color {
    static let blackSprout = Color(hex: "#82957B")
    static let deepSprout = Color(hex: "#B7C8B1")
    static let brightSprout = Color(hex: "#E0E4D9")
    static let brightForsythia = Color(hex: "#FDC020")

    static let gray0 = Color(hex: "#FFFFFF")
    static let gray15 = Color(hex: "#F9F9F9")
    static let gray30 = Color(hex: "#EAEAEA")
    static let gray45 = Color(hex: "#D8D6D7")
    static let gray60 = Color(hex: "#ABABAE")
    static let gray75 = Color(hex: "#6A6A6E")
    static let gray90 = Color(hex: "#434347")
    static let gray100 = Color(hex: "#0B0B0B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
