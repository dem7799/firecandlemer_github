import Foundation
import CryptoKit

final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private var progressHandlers: [Int: (Double) -> Void] = [:]
    private var completionHandlers: [Int: (Result<URL, Error>) -> Void] = [:]

    private override init() {}

    // MARK: - Public API

    func cachedFileURL(for url: URL) -> URL {
        let fileName = Self.sha256(url.absoluteString)
        let ext = url.pathExtension
        let name = ext.isEmpty ? fileName : "\(fileName).\(ext)"
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent(name)
    }

    func fileExists(for url: URL) -> Bool {
        FileManager.default.fileExists(atPath: cachedFileURL(for: url).path)
    }

    func downloadIfNeeded(url: URL, onProgress: ((Double) -> Void)? = nil) async throws -> URL {
        let destination = cachedFileURL(for: url)
        if FileManager.default.fileExists(atPath: destination.path) {
            onProgress?(1.0)
            return destination
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let task = self.session.downloadTask(with: url)
            self.progressHandlers[task.taskIdentifier] = { progress in
                onProgress?(progress)
            }
            self.completionHandlers[task.taskIdentifier] = { result in
                switch result {
                case .success(let tempURL):
                    do {
                        try Self.moveDownloadedFile(from: tempURL, to: destination)
                        continuation.resume(returning: destination)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandlers[downloadTask.taskIdentifier]?(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        completionHandlers[downloadTask.taskIdentifier]?(.success(location))
        cleanup(taskIdentifier: downloadTask.taskIdentifier)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandlers[task.taskIdentifier]?(.failure(error))
            cleanup(taskIdentifier: task.taskIdentifier)
        }
    }

    private func cleanup(taskIdentifier: Int) {
        progressHandlers[taskIdentifier] = nil
        completionHandlers[taskIdentifier] = nil
    }

    // MARK: - Helpers

    private static func sha256(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func moveDownloadedFile(from src: URL, to dst: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: dst.path) {
            try fm.removeItem(at: dst)
        }
        try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.moveItem(at: src, to: dst)
    }
}

