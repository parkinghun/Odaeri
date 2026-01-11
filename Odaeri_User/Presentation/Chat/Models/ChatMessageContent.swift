//
//  ChatMessageContent.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import Foundation

enum ChatMessageContent: Hashable {
    case text(String)
    case imageGroup([String])
    case video(String)
    case file(FileInfo)

    struct FileInfo: Hashable {
        let url: String
        let fileName: String
        let fileSize: String?
    }
}

extension ChatMessageContent {
    static func parse(
        chatId: String,
        content: String,
        files: [String]
    ) -> [ChatMessageContent] {
        var result: [ChatMessageContent] = []

        if !content.isEmpty {
            result.append(.text(content))
        }

        if !files.isEmpty {
            var i = 0
            while i < files.count {
                let file = files[i]
                let ext = URL(string: file)?.pathExtension.lowercased() ?? ""

                if isImageExtension(ext) {
                    var imageUrls: [String] = []
                    var j = i

                    while j < files.count && imageUrls.count < 5 {
                        let currentFile = files[j]
                        let currentExt = URL(string: currentFile)?.pathExtension.lowercased() ?? ""

                        if isImageExtension(currentExt) {
                            imageUrls.append(currentFile)
                            j += 1
                        } else {
                            break
                        }
                    }

                    result.append(.imageGroup(imageUrls))
                    i = j

                } else if isVideoExtension(ext) {
                    result.append(.video(file))
                    i += 1

                } else if ext == "pdf" {
                    let fileName = URL(string: file)?
                        .lastPathComponent
                        .removingPercentEncoding ?? "document.pdf"
                    let fileInfo = FileInfo(url: file, fileName: fileName, fileSize: nil)
                    result.append(.file(fileInfo))
                    i += 1

                } else {
                    i += 1
                }
            }
        }

        return result
    }

    private static func isImageExtension(_ ext: String) -> Bool {
        return ["jpg", "jpeg", "png", "gif"].contains(ext)
    }

    private static func isVideoExtension(_ ext: String) -> Bool {
        return ["mp4", "mov", "avi", "mkv", "m4v"].contains(ext)
    }
}
