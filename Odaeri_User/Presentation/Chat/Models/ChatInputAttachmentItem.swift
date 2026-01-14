//
//  ChatInputAttachmentItem.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit

enum ChatInputAttachmentItem: Hashable {
    case image(UIImage, fileName: String?, id: String)
    case video(fileName: String, thumbnail: UIImage?, id: String)
    case file(fileName: String, displayName: String, fileType: FileType, id: String)

    enum FileType: Hashable {
        case pdf
        case zip
        case other

        static func from(url: URL) -> FileType {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "pdf":
                return .pdf
            case "zip":
                return .zip
            default:
                return .other
            }
        }

        static func from(fileExtension: String) -> FileType {
            switch fileExtension.lowercased() {
            case "pdf":
                return .pdf
            case "zip":
                return .zip
            default:
                return .other
            }
        }

        var icon: UIImage {
            switch self {
            case .pdf:
                return AppImage.pdf
                    .withRenderingMode(.alwaysOriginal)
            case .zip:
                return AppImage.zip
                    .withRenderingMode(.alwaysOriginal)
            case .other:
                return AppImage.document
                    .withRenderingMode(.alwaysOriginal)
            }
        }
    }

    var id: String {
        switch self {
        case .image(_, _, let id),
             .video(_, _, let id),
             .file(_, _, _, let id):
            return id
        }
    }

    var displayImage: UIImage? {
        switch self {
        case .image(let image, _, _):
            return image
        case .video(_, let thumbnail, _):
            return thumbnail
        case .file(_, _, let fileType, _):
            return fileType.icon
        }
    }

    var isVideo: Bool {
        if case .video = self {
            return true
        }
        return false
    }

    var displayFileName: String? {
        switch self {
        case .file(_, let displayName, _, _):
            return displayName
        default:
            return nil
        }
    }

    var localURLString: String? {
        switch self {
        case .image(_, let fileName, _):
            return fileName
        case .video(let fileName, _, _):
            return fileName
        case .file(let fileName, _, _, _):
            return fileName
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatInputAttachmentItem, rhs: ChatInputAttachmentItem) -> Bool {
        return lhs.id == rhs.id
    }
}
