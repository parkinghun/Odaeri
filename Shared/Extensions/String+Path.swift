//
//  String+Path.swift
//  Odaeri
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation

extension String {
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }

    var pathExtension: String {
        return (self as NSString).pathExtension
    }

    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }

    func appendingPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
}
