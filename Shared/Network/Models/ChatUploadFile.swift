//
//  ChatUploadFile.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation

struct ChatUploadFile {
    enum Source {
        case data(Data)
        case file(URL)
    }

    let source: Source
    let fileName: String
    let mimeType: String
}
