//
//  WebViewManaging.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation

protocol WebViewManaging: AnyObject {
    func createURLRequest(for path: String) -> URLRequest?
}
