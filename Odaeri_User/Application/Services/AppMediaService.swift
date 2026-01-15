//
//  AppMediaService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import UIKit
import AVKit
import Moya
import Combine

final class AppMediaService: NSObject {
    static let shared = AppMediaService()
    
    private let provider = MoyaProvider<MediaAPI>()
    private let fileManager = FileManager.default
    private let imageCacheManager = ImageCacheManager.shared
    private let diskCacheManager = DiskCacheManager.shared
    private let serviceQueue = DispatchQueue(label: "com.odaeri.mediaservice", attributes: .concurrent)
    
    private var inFlightTasks: [String: AnyCancellable] = [:]
    private var inFlightThumbnailTasks: [String: DispatchWorkItem] = [:]
    
    private var documentInteractionController: UIDocumentInteractionController?
    
    private let videoCacheDirectory: URL
    private let fileCacheDirectory: URL
    private let thumbnailCacheDirectory: URL
    
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60
    private let maxCacheSize: Int64 = 500 * 1024 * 1024
    
    private override init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.videoCacheDirectory = cachesDirectory.appendingPathComponent("Videos", isDirectory: true)
        self.fileCacheDirectory = cachesDirectory.appendingPathComponent("Files", isDirectory: true)
        self.thumbnailCacheDirectory = cachesDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
        
        super.init()
        
        createDirectoriesIfNeeded()
        performCacheCleanup()
    }
    
    private func normalize(_ path: String) -> String {
        print("[AppMediaService] 경로 정규화 시작: \(path)")

        if path.hasPrefix("http") {
            print("[AppMediaService] HTTP URL 그대로 사용")
            return path
        }

        if path.hasPrefix("file://") {
            print("[AppMediaService] 절대 경로 그대로 사용")
            return path
        }

        if let localFileURL = FilePathManager.getFileURL(from: path) {
            let normalizedPath = localFileURL.absoluteString
            print("[AppMediaService] 로컬 파일 경로로 변환: \(normalizedPath)")
            return normalizedPath
        }

        let base = APIEnvironment.current.baseURL.absoluteString.hasSuffix("/")
        ? String(APIEnvironment.current.baseURL.absoluteString.dropLast())
        : APIEnvironment.current.baseURL.absoluteString

        let version = APIEnvironment.current.version

        var cleanPath = path
        if cleanPath.hasPrefix("./") { cleanPath.removeFirst(2) }
        if cleanPath.hasPrefix("/") { cleanPath.removeFirst() }

        let serverPath = "\(base)/\(version)/\(cleanPath)"
        print("[AppMediaService] 서버 경로로 변환: \(serverPath)")
        return serverPath
    }
    
    private func createDirectoriesIfNeeded() {
        [videoCacheDirectory, fileCacheDirectory, thumbnailCacheDirectory].forEach { directory in
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
    }
    
    private func extractExtension(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.query = nil
        components.fragment = nil
        
        guard let cleanURL = components.url else {
            return nil
        }
        
        let pathExtension = cleanURL.pathExtension
        return pathExtension.isEmpty ? nil : pathExtension
    }
    
    private func cacheKey(for url: String) -> String {
        let normalizedURL = normalize(url)
        guard let fileExtension = extractExtension(from: normalizedURL) else {
            return normalizedURL.sha256()
        }
        return "\(normalizedURL.sha256()).\(fileExtension)"
    }
    
    private func cachedFileURL(for url: String, in directory: URL) -> URL {
        let key = cacheKey(for: url)
        return directory.appendingPathComponent(key)
    }

    func resolvePlayableURL(for url: String) -> URL? {
        if let fileURL = URL(string: url), fileURL.isFileURL {
            return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
        }

        let localURL = cachedFileURL(for: url, in: videoCacheDirectory)
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        let normalizedURL = normalize(url)
        return URL(string: normalizedURL)
    }
    
    func fetchThumbnail(url: String, completion: @escaping (UIImage?) -> Void) {
        let thumbnailKey = cacheKey(for: url)
        
        if let cachedThumbnail = imageCacheManager.getCachedImage(forKey: thumbnailKey) {
            completion(cachedThumbnail)
            return
        }
        
        let thumbnailURL = thumbnailCacheDirectory.appendingPathComponent(thumbnailKey)
        
        if fileManager.fileExists(atPath: thumbnailURL.path),
           let thumbnail = UIImage(contentsOfFile: thumbnailURL.path) {
            imageCacheManager.cacheImage(thumbnail, forKey: thumbnailKey)
            completion(thumbnail)
            return
        }
        
        serviceQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if self.inFlightThumbnailTasks[thumbnailKey] != nil {
                return
            }
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                let localVideoURL = self.cachedFileURL(for: url, in: self.videoCacheDirectory)
                let sourceURL: URL
                
                if self.fileManager.fileExists(atPath: localVideoURL.path) {
                    sourceURL = localVideoURL
                } else {
                    let normalizedURL = self.normalize(url)
                    guard let remoteURL = URL(string: normalizedURL) else {
                        DispatchQueue.main.async { completion(nil) }
                        return
                    }
                    sourceURL = remoteURL
                }
                
                let asset = AVAsset(url: sourceURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 800, height: 800)
                imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 2.0, preferredTimescale: 600)
                imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 2.0, preferredTimescale: 600)
                
                let time = CMTime(seconds: 0.0, preferredTimescale: 600)
                
                do {
                    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    let thumbnail = UIImage(cgImage: cgImage)
                    
                    if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                        try? jpegData.write(to: thumbnailURL)
                    }
                    
                    self.imageCacheManager.cacheImage(thumbnail, forKey: thumbnailKey)
                    
                    self.serviceQueue.async(flags: .barrier) {
                        self.inFlightThumbnailTasks.removeValue(forKey: thumbnailKey)
                    }
                    
                    DispatchQueue.main.async {
                        completion(thumbnail)
                    }
                } catch {
                    self.serviceQueue.async(flags: .barrier) {
                        self.inFlightThumbnailTasks.removeValue(forKey: thumbnailKey)
                    }
                    
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            
            self.inFlightThumbnailTasks[thumbnailKey] = workItem
            DispatchQueue.global(qos: .utility).async(execute: workItem)
        }
    }
    
    func cancelThumbnailGeneration(for url: String) {
        let thumbnailKey = cacheKey(for: url)
        
        serviceQueue.async(flags: .barrier) { [weak self] in
            if let workItem = self?.inFlightThumbnailTasks[thumbnailKey] {
                workItem.cancel()
                self?.inFlightThumbnailTasks.removeValue(forKey: thumbnailKey)
            }
        }
    }
    
    func playVideo(url: String, from viewController: UIViewController) {
        guard viewController.view.window != nil else {
            return
        }
        
        let cachedVideoURL = cachedFileURL(for: url, in: videoCacheDirectory)
        
        if fileManager.fileExists(atPath: cachedVideoURL.path) {
            presentVideoPlayer(with: cachedVideoURL, from: viewController)
            return
        }
        
        downloadVideo(url: url) { [weak self, weak viewController] result in
            guard let self = self, let viewController = viewController else { return }
            
            switch result {
            case .success(let localURL):
                self.generateThumbnail(for: localURL, originalURL: url)
                self.presentVideoPlayer(with: localURL, from: viewController)
            case let .failure(error):
                print("❌ Download Error: \(error)")
                break
            }
        }
    }
    
    private func downloadVideo(url: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let normalizedURL = normalize(url)
        let cacheKey = self.cacheKey(for: url)
        
        serviceQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if self.inFlightTasks[cacheKey] != nil {
                return
            }
            
            let destinationURL = self.cachedFileURL(for: url, in: self.videoCacheDirectory)
            
            let publisher = Future<URL, Error> { promise in
                self.provider.request(.downloadMediaToDisk(fullURL: normalizedURL, destination: destinationURL)) { result in
                    switch result {
                    case .success:
                        promise(.success(destinationURL))
                    case .failure(let error):
                        if self.fileManager.fileExists(atPath: destinationURL.path) {
                            try? self.fileManager.removeItem(at: destinationURL)
                        }
                        promise(.failure(error))
                    }
                }
            }
            
            let cancellable = publisher
                .sink(
                    receiveCompletion: { [weak self] result in
                        guard let self = self else { return }
                        
                        self.serviceQueue.async(flags: .barrier) {
                            self.inFlightTasks.removeValue(forKey: cacheKey)
                        }
                        
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    },
                    receiveValue: { localURL in
                        DispatchQueue.main.async {
                            completion(.success(localURL))
                        }
                    }
                )
            
            self.inFlightTasks[cacheKey] = cancellable
        }
    }
    
    private func generateThumbnail(for videoURL: URL, originalURL: String) {
        let thumbnailKey = cacheKey(for: originalURL)
        let thumbnailURL = thumbnailCacheDirectory.appendingPathComponent(thumbnailKey)
        
        guard !fileManager.fileExists(atPath: thumbnailURL.path) else {
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 800, height: 800)
            imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 2.0, preferredTimescale: 600)
            imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 2.0, preferredTimescale: 600)
            
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                
                if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try? jpegData.write(to: thumbnailURL)
                }
                
                self.imageCacheManager.cacheImage(thumbnail, forKey: thumbnailKey)
            } catch {
                print("Thumbnail generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func presentVideoPlayer(with url: URL, from viewController: UIViewController) {
        DispatchQueue.main.async {
            guard viewController.view.window != nil else {
                return
            }
            
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            viewController.present(playerViewController, animated: true) {
                player.play()
            }
        }
    }
    
    func previewFile(url: String, fileName: String, from viewController: UIViewController) {
        guard viewController.view.window != nil else {
            return
        }
        
        let cachedFileURL = cachedFileURL(for: url, in: fileCacheDirectory)
        
        if fileManager.fileExists(atPath: cachedFileURL.path) {
            presentDocumentInteraction(with: cachedFileURL, from: viewController)
            return
        }
        
        downloadFile(url: url) { [weak self, weak viewController] result in
            guard let self = self, let viewController = viewController else { return }
            
            switch result {
            case .success(let localURL):
                self.presentDocumentInteraction(with: localURL, from: viewController)
            case .failure:
                break
            }
        }
    }
    
    private func downloadFile(url: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let normalizedURL = normalize(url)
        let cacheKey = self.cacheKey(for: url)
        
        serviceQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if self.inFlightTasks[cacheKey] != nil {
                return
            }
            
            let destinationURL = self.cachedFileURL(for: url, in: self.fileCacheDirectory)
            
            let publisher = Future<URL, Error> { promise in
                self.provider.request(.downloadMediaToDisk(fullURL: normalizedURL, destination: destinationURL)) { result in
                    switch result {
                    case .success:
                        promise(.success(destinationURL))
                    case .failure(let error):
                        if self.fileManager.fileExists(atPath: destinationURL.path) {
                            try? self.fileManager.removeItem(at: destinationURL)
                        }
                        promise(.failure(error))
                    }
                }
            }
            
            let cancellable = publisher
                .sink(
                    receiveCompletion: { [weak self] result in
                        guard let self = self else { return }
                        
                        self.serviceQueue.async(flags: .barrier) {
                            self.inFlightTasks.removeValue(forKey: cacheKey)
                        }
                        
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    },
                    receiveValue: { localURL in
                        DispatchQueue.main.async {
                            completion(.success(localURL))
                        }
                    }
                )
            
            self.inFlightTasks[cacheKey] = cancellable
        }
    }
    
    private func presentDocumentInteraction(with url: URL, from viewController: UIViewController) {
        DispatchQueue.main.async { [weak self, weak viewController] in
            guard let self = self, let viewController = viewController else { return }
            guard viewController.view.window != nil else {
                return
            }
            
            self.documentInteractionController = UIDocumentInteractionController(url: url)
            self.documentInteractionController?.delegate = self
            self.documentInteractionController?.presentPreview(animated: true)
        }
    }
    
    private func performCacheCleanup() {
        serviceQueue.async { [weak self] in
            guard let self = self else { return }
            
            let directories = [
                self.videoCacheDirectory,
                self.fileCacheDirectory,
                self.thumbnailCacheDirectory
            ]
            
            for directory in directories {
                self.cleanupDirectory(directory)
            }
        }
    }
    
    private func cleanupDirectory(_ directory: URL) {
        let expirationDate = Date().addingTimeInterval(-maxCacheAge)
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return
        }
        
        var totalSize: Int64 = 0
        var files: [(url: URL, size: Int64, date: Date)] = []
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let modificationDate = resourceValues.contentModificationDate,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            
            if modificationDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)
                continue
            }
            
            let size = Int64(fileSize)
            totalSize += size
            files.append((url: fileURL, size: size, date: modificationDate))
        }
        
        guard totalSize > maxCacheSize else {
            return
        }
        
        files.sort { $0.date < $1.date }
        
        let targetSize = Int64(Double(maxCacheSize) * 0.7)
        
        for file in files {
            guard totalSize > targetSize else {
                break
            }
            
            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size
        }
    }
    
    func clearVideoCache(completion: (() -> Void)? = nil) {
        serviceQueue.async { [weak self] in
            guard let self = self else { return }
            
            try? self.fileManager.removeItem(at: self.videoCacheDirectory)
            try? self.fileManager.removeItem(at: self.thumbnailCacheDirectory)
            self.createDirectoriesIfNeeded()
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func clearFileCache(completion: (() -> Void)? = nil) {
        serviceQueue.async { [weak self] in
            guard let self = self else { return }
            
            try? self.fileManager.removeItem(at: self.fileCacheDirectory)
            self.createDirectoriesIfNeeded()
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}

extension AppMediaService: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return UIViewController()
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
