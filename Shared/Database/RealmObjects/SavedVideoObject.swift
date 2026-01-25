//
//  SavedVideoObject.swift
//  Odaeri
//
//  Created by 박성훈 on 01/25/26.
//

import Foundation
import RealmSwift

final class SavedVideoObject: Object {
    @Persisted(primaryKey: true) var videoId: String
    @Persisted var savedAt: Date

    convenience init(videoId: String, savedAt: Date = Date()) {
        self.init()
        self.videoId = videoId
        self.savedAt = savedAt
    }
}
