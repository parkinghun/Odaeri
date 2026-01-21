//
//  Int+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation

extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

