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
    case video(thumbnailUrl: String, videoUrl: String)
    case file(FileInfo)
    case shareCard(ShareCardPayload)

    struct FileInfo: Hashable {
        let url: String
        let fileName: String
        let fileSize: String?
        let fileType: ChatFileType
    }
}

extension ChatMessageContent {
    func toMediaItems() -> [MediaItem] {
        switch self {
        case .imageGroup(let urls):
            return urls.map { MediaItem.image(url: $0) }
        case .video(let thumbnailUrl, let videoUrl):
            return [MediaItem.video(url: videoUrl, thumbnailUrl: thumbnailUrl)]
        default:
            return []
        }
    }
}

extension ChatMessageContent {
    static func parse(
        chatId: String,
        content: String,
        files: [String]
    ) -> [ChatMessageContent] {
        var result: [ChatMessageContent] = []

        if let payload = ShareCardMessageFormatter.parse(content: content) {
            result.append(.shareCard(payload))
        } else if !content.isEmpty {
            result.append(.text(content))
        }

        let fileContents = parseFiles(files: files)
        result.append(contentsOf: fileContents)

        return result
    }

    static func parseFiles(files: [String]) -> [ChatMessageContent] {
        var result: [ChatMessageContent] = []

        guard !files.isEmpty else {
            return result
        }

        var i = 0
        while i < files.count {
            let file = files[i]
            let ext = fileExtension(from: file)

            if isImageExtension(ext) {
                let nextIndex = i + 1
                let isFollowedByVideo = nextIndex < files.count && isVideoExtension(fileExtension(from: files[nextIndex]))

                if isFollowedByVideo {
                    let thumbnailUrl = file
                    let videoUrl = files[nextIndex]
                    result.append(.video(thumbnailUrl: thumbnailUrl, videoUrl: videoUrl))
                    i += 2
                } else {
                    var imageUrls: [String] = []
                    var j = i

                    while j < files.count && imageUrls.count < 5 {
                        let currentFile = files[j]
                        let currentExt = fileExtension(from: currentFile)
                        let nextJ = j + 1
                        let isCurrentFollowedByVideo = nextJ < files.count && isVideoExtension(fileExtension(from: files[nextJ]))

                        if isImageExtension(currentExt) && !isCurrentFollowedByVideo {
                            imageUrls.append(currentFile)
                            j += 1
                        } else {
                            break
                        }
                    }

                    if !imageUrls.isEmpty {
                        result.append(.imageGroup(imageUrls))
                        i = j
                    } else {
                        i += 1
                    }
                }

            } else if isVideoExtension(ext) {
                result.append(.video(thumbnailUrl: file, videoUrl: file))
                i += 1

            } else {
                let fileName = fileName(from: file)
                let fileType = ChatFileType.from(fileExtension: ext)
                let fileInfo = FileInfo(
                    url: file,
                    fileName: fileName,
                    fileSize: nil,
                    fileType: fileType
                )
                result.append(.file(fileInfo))
                i += 1
            }
        }

        return result
    }

    private static func resolveFileURL(from fileString: String) -> URL? {
        guard !fileString.isEmpty else {
            print("[ChatMessageContent] 빈 파일 문자열")
            return nil
        }

        if fileString.hasPrefix("http://") || fileString.hasPrefix("https://") {
            return URL(string: fileString)
        }

        if fileString.hasPrefix("file://") {
            if let url = URL(string: fileString) {
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                print("[ChatMessageContent] 절대 경로 처리: \(url.path), 존재: \(fileExists)")

                if fileExists {
                    return url
                } else {
                    let fileName = url.lastPathComponent
                    print("[ChatMessageContent] 절대 경로 실패, 파일명으로 재시도: \(fileName)")
                    return FilePathManager.getFileURL(from: fileName)
                }
            }
        }

        print("[ChatMessageContent] 파일명으로 처리: \(fileString)")
        return FilePathManager.getFileURL(from: fileString)
    }

    private static func fileExtension(from fileString: String) -> String {
        let sanitized = fileString.split(separator: "?").first.map(String.init) ?? fileString
        if let url = URL(string: sanitized), !sanitized.hasPrefix("/") {
            return url.pathExtension.lowercased()
        }
        return (sanitized as NSString).pathExtension.lowercased()
    }

    private static func fileName(from fileString: String) -> String {
        let sanitized = fileString.split(separator: "?").first.map(String.init) ?? fileString
        if let url = URL(string: sanitized), !sanitized.hasPrefix("/") {
            return url.lastPathComponent.removingPercentEncoding ?? "document"
        }
        let name = (sanitized as NSString).lastPathComponent
        return name.removingPercentEncoding ?? "document"
    }

    private static func isImageExtension(_ ext: String) -> Bool {
        return ["jpg", "jpeg", "png", "gif"].contains(ext)
    }

    private static func isVideoExtension(_ ext: String) -> Bool {
        return ["mp4", "mov", "avi", "mkv", "m4v"].contains(ext)
    }
}
