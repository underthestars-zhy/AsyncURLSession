import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct AsyncURLSession {
    public static let shared = Self()

    public let urlSession: URLSession

    public init() {
        self.urlSession = URLSession.shared
    }

    public init(configuration: URLSessionConfiguration) {
        self.urlSession = URLSession(configuration: configuration)
    }

    public func url(for request: URLRequest) async throws -> (URL, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            urlSession.downloadTask(with: request) { url, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url, let response = response {
                    continuation.resume(returning: (url, response))
                } else {
                    continuation.resume(throwing: AsyncURLSessionError())
                }
            }
            .resume()
        }
    }

    public func url(from downloadURL: URL) async throws -> (URL, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            urlSession.downloadTask(with: downloadURL) { url, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url, let response = response {
                    continuation.resume(returning: (url, response))
                } else {
                    continuation.resume(throwing: AsyncURLSessionError())
                }
            }
            .resume()
        }
    }

    public func download(for request: URLRequest, location: URL) async throws -> (AsyncThrowingStream<Int, Error>, URLResponse, Task<Void, Never>) {
        let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(for: request)
        let length = Int(urlResponse.expectedContentLength)

        var task: Task<Void, Never> = Task {}

        let stream = AsyncThrowingStream<Int, Error> { continuation in
            task = Task {
                var current = 0
                var data = Data()
                data.reserveCapacity(length / 100)

                do {
                    for try await byte in asyncBytes {
                        data.append(byte)
                        current += 1

                        continuation.yield(current)

                        if data.count == length / 100 {
                            try data.append(fileURL: location)
                            data.removeAll()
                        }
                    }

                    if !data.isEmpty {
                        try data.append(fileURL: location)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return (stream, urlResponse, task)
    }

    public func download(from url: URL, location: URL) async throws -> (AsyncThrowingStream<Int, Error>, URLResponse, Task<Void, Never>) {
        let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
        let length = Int(urlResponse.expectedContentLength)

        var task: Task<Void, Never> = Task {}

        let stream = AsyncThrowingStream<Int, Error> { continuation in
            task = Task.detached {
                var current = 0
                var data = Data()
                data.reserveCapacity(length / 100)

                do {
                    for try await byte in asyncBytes {
                        data.append(byte)
                        current += 1

                        continuation.yield(current)

                        if data.count == length / 100 {
                            try data.append(fileURL: location)
                            data.removeAll()
                        }

                        try Task.checkCancellation()
                    }

                    if !data.isEmpty {
                        try data.append(fileURL: location)
                    }

                    continuation.finish(throwing: nil)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return (stream, urlResponse, task)
    }

    fileprivate struct AsyncURLSessionError: Error {
        let describe = "Something wrong with url session async download"
    }
}
