//
//  AppImage.swift
//  Odaeri
//
//  Created by 박성훈 on 12/15/25.
//

import UIKit

enum AppImage {
    private static func image(_ name: String) -> UIImage {
        guard let image = UIImage(named: name) else {
            return UIImage()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
    
    private static func systemImage(_ name: String) -> UIImage {
        guard let image = UIImage(systemName: name) else {
            return UIImage()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Category
    static let bakery = UIImage(named: "Bakery")
    static let coffee = UIImage(named: "Coffee")
    static let dessert = UIImage(named: "Dessert")
    static let fastFood = UIImage(named: "FastFood")
    static let more = UIImage(named: "More")
    
    // MARK: - Icon
    static let check = image("Check")
    static let checkmarkFill = systemImage("checkmark.square.fill")
    static let checkmarkEmpty = systemImage("checkmark.square")
    static let chevron = image("chevron")
    static let cheveronRight = systemImage("chevron.forward")
    static let `default` = image("Default")
    static let detail = image("Detail")
    static let distance = image("Distance")
    static let likeEmpty = image("Like_Empty")
    static let likeFill = image("Like_Fill")
    static let list = image("List")
    static let location = image("Location")
    static let parking = image("Parking")
    static let run = image("Run")
    static let search = image("Search")
    static let sesac = image("Sesac")
    static let starEmpty = image("Star_Empty")
    static let starFill = image("Star_Fill")
    static let time = image("Time")
    static let write = image("Write")
    static let bike = image("bike")
    static let progressFinish = systemImage("checkmark.circle.fill")
    static let progressDefault = systemImage("record.circle.fill")
    
    
    // MARK: - TabBar
    static let communityEmpty = UIImage(named: "Community_Empty")
    static let communityFill = UIImage(named: "Community_Fill")
    static let homeEmpty = UIImage(named: "Home_Empty")
    static let homeFill = UIImage(named: "Home_Fill")
    static let orderEmpty = UIImage(named: "Order_Empty")
    static let orderFill = UIImage(named: "Order_Fill")
    static let pickEmpty = UIImage(named: "Pick_Empty")
    static let pickFill = UIImage(named: "Pick_Fill")
    static let profileEmpty = UIImage(named: "Profile_Empty")
    static let profileFill = UIImage(named: "Profile_Fill")
    
    // MARK: - Ohters
    static let pickchelin = UIImage(named: "PickchelinTag")
}

