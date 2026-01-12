//
//  ChatInputAttachmentItem.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit
import AVFoundation
import UniformTypeIdentifiers

enum ChatInputAttachmentItem: Hashable {
    case image(UIImage, fileURL: URL?, id: String)
    case video(URL, thumbnail: UIImage?, id: String)
    case file(URL, fileName: String, fileType: FileType, id: String)

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

    var fileName: String? {
        switch self {
        case .file(_, let fileName, _, _):
            return fileName
        default:
            return nil
        }
    }

    var uploadFile: ChatUploadFile? {
        switch self {
        case .image(let image, let fileURL, let id):
            if let fileURL = fileURL {
                return ChatUploadFile(
                    source: .file(fileURL),
                    fileName: fileURL.lastPathComponent,
                    mimeType: mimeType(for: fileURL)
                )
            }

            guard let data = image.jpegData(compressionQuality: 0.8) else {
                return nil
            }

            return ChatUploadFile(
                source: .data(data),
                fileName: "chat_image_\(id).jpg",
                mimeType: "image/jpeg"
            )

        case .video(let url, _, _):
            return ChatUploadFile(
                source: .file(url),
                fileName: url.lastPathComponent,
                mimeType: mimeType(for: url)
            )

        case .file(let url, let fileName, _, _):
            return ChatUploadFile(
                source: .file(url),
                fileName: fileName,
                mimeType: mimeType(for: url)
            )
        }
    }

    var localURLString: String? {
        switch self {
        case .image(_, let fileURL, _):
            return fileURL?.absoluteString
        case .video(let url, _, _):
            return url.absoluteString
        case .file(let url, _, _, _):
            return url.absoluteString
        }
    }

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            break
        }
        if let type = UTType(filenameExtension: ext) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatInputAttachmentItem, rhs: ChatInputAttachmentItem) -> Bool {
        return lhs.id == rhs.id
    }
}
