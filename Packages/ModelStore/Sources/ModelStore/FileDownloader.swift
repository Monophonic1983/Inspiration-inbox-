import Foundation

/// One resumable file download. Resume data is persisted next to the destination so an interrupted
/// download (app kill, network loss) continues instead of restarting.
final class FileDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var session: URLSession!
    private var task: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private var onProgress: (@Sendable (Int64) -> Void)?
    private let resumeURL: URL

    init(resumeDataURL: URL, wifiOnly: Bool) {
        self.resumeURL = resumeDataURL
        super.init()
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = !wifiOnly
        config.allowsExpensiveNetworkAccess = !wifiOnly
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func download(from url: URL, onProgress: @escaping @Sendable (Int64) -> Void) async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                lock.lock()
                self.continuation = cont
                self.onProgress = onProgress
                if let data = try? Data(contentsOf: resumeURL) {
                    task = session.downloadTask(withResumeData: data)
                    try? FileManager.default.removeItem(at: resumeURL)
                } else {
                    task = session.downloadTask(with: url)
                }
                task?.resume()
                lock.unlock()
            }
        } onCancel: {
            self.cancelKeepingResumeData()
        }
    }

    private func cancelKeepingResumeData() {
        lock.lock(); let t = task; lock.unlock()
        t?.cancel(byProducingResumeData: { [resumeURL] data in
            if let data { try? data.write(to: resumeURL) }
        })
    }

    private func finish(_ result: Result<URL, Error>) {
        lock.lock(); let c = continuation; continuation = nil; lock.unlock()
        c?.resume(with: result)
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ s: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite _: Int64) {
        onProgress?(totalBytesWritten)
    }

    func urlSession(_ s: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // The temp file is deleted when this returns, so move it first.
        let kept = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            try FileManager.default.moveItem(at: location, to: kept)
            finish(.success(kept))
        } catch { finish(.failure(error)) }
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if let data = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            try? data.write(to: resumeURL)
        }
        finish(.failure(error))
    }
}
