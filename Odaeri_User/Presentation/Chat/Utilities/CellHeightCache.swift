//
//  CellHeightCache.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit

final class CellHeightCache {
    private var cache: [String: CGFloat] = [:]

    func height(for id: String) -> CGFloat? {
        return cache[id]
    }

    func setHeight(_ height: CGFloat, for id: String) {
        cache[id] = height
    }

    func removeHeight(for id: String) {
        cache.removeValue(forKey: id)
    }

    func clear() {
        cache.removeAll()
    }
}
