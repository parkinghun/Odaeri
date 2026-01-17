//
//  StoreSearchDelegate.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation

protocol StoreSearchDelegate: AnyObject {
    func didSelectStore(storeId: String)
}
