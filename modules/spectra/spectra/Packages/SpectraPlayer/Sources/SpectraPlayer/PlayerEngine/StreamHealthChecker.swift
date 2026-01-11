import Foundation
import SpectraCore

/// Validates streams and performs health checks
public actor StreamHealthChecker {
    
    public struct HealthCheckResult: Sendable {
        public let streamId: UUID
        public let url: URL
        public let isHealthy: Bool
        public let statusCode: Int?
        public let responseTime: TimeInterval?
        public let error: String?
        public let checkedAt: Date
    }
    
    private let session: URLSession
    private let timeout: TimeInterval
    
    public init(timeout: TimeInterval = 10) {
        self.timeout = timeout
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.waitsForConnectivity = false
        
        self.session = URLSession(configuration: config)
    }
    
    /// Check health of a single stream
    public func check(stream: MediaStream) async -> HealthCheckResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Determine check strategy based on stream type
        if stream.isHLS {
            return await checkHLS(stream: stream, startTime: startTime)
        } else {
            return await checkGeneric(stream: stream, startTime: startTime)
        }
    }
    
    /// Check multiple streams concurrently
    public func checkBatch(streams: [MediaStream], maxConcurrency: Int = 5) async -> [HealthCheckResult] {
        await withTaskGroup(of: HealthCheckResult.self) { group in
            var results: [HealthCheckResult] = []
            var pending = streams[...]
            
            // Start initial batch
            for _ in 0..<min(maxConcurrency, streams.count) {
                if let stream = pending.popFirst() {
                    group.addTask {
                        await self.check(stream: stream)
                    }
                }
            }
            
            // Process results and add new tasks
            for await result in group {
                results.append(result)
                
                if let stream = pending.popFirst() {
                    group.addTask {
                        await self.check(stream: stream)
                    }
                }
            }
            
            return results
        }
    }
    
    // MARK: - Private
    
    private func checkHLS(stream: MediaStream, startTime: CFAbsoluteTime) async -> HealthCheckResult {
        var request = URLRequest(url: stream.url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        
        // Add custom headers if specified
        if let userAgent = stream.userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        if let referrer = stream.referrer {
            request.setValue(referrer, forHTTPHeaderField: "Referer")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return HealthCheckResult(
                    streamId: stream.id,
                    url: stream.url,
                    isHealthy: false,
                    statusCode: nil,
                    responseTime: responseTime,
                    error: "Invalid response",
                    checkedAt: Date()
                )
            }
            
            let isSuccess = (200...299).contains(httpResponse.statusCode)
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
            
            // For HLS, verify we got a playlist
            var isValidContent = false
            if isSuccess {
                if let content = String(data: data, encoding: .utf8) {
                    isValidContent = content.contains("#EXTM3U") || content.contains("#EXT-X-")
                }
                // Also accept based on content type
                if contentType.contains("mpegurl") || contentType.contains("x-mpegURL") {
                    isValidContent = true
                }
            }
            
            return HealthCheckResult(
                streamId: stream.id,
                url: stream.url,
                isHealthy: isSuccess && isValidContent,
                statusCode: httpResponse.statusCode,
                responseTime: responseTime,
                error: isSuccess && !isValidContent ? "Not a valid HLS playlist" : nil,
                checkedAt: Date()
            )
            
        } catch {
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            return HealthCheckResult(
                streamId: stream.id,
                url: stream.url,
                isHealthy: false,
                statusCode: nil,
                responseTime: responseTime,
                error: error.localizedDescription,
                checkedAt: Date()
            )
        }
    }
    
    private func checkGeneric(stream: MediaStream, startTime: CFAbsoluteTime) async -> HealthCheckResult {
        var request = URLRequest(url: stream.url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        
        if let userAgent = stream.userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        if let referrer = stream.referrer {
            request.setValue(referrer, forHTTPHeaderField: "Referer")
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return HealthCheckResult(
                    streamId: stream.id,
                    url: stream.url,
                    isHealthy: false,
                    statusCode: nil,
                    responseTime: responseTime,
                    error: "Invalid response",
                    checkedAt: Date()
                )
            }
            
            let isSuccess = (200...299).contains(httpResponse.statusCode)
            
            return HealthCheckResult(
                streamId: stream.id,
                url: stream.url,
                isHealthy: isSuccess,
                statusCode: httpResponse.statusCode,
                responseTime: responseTime,
                error: nil,
                checkedAt: Date()
            )
            
        } catch {
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            return HealthCheckResult(
                streamId: stream.id,
                url: stream.url,
                isHealthy: false,
                statusCode: nil,
                responseTime: responseTime,
                error: error.localizedDescription,
                checkedAt: Date()
            )
        }
    }
}

/// Helper to determine stream health status from check results
public func determineHealthStatus(
    from result: StreamHealthChecker.HealthCheckResult,
    currentFailureCount: Int,
    deadThreshold: Int = 3
) -> (status: StreamHealthStatus, newFailureCount: Int) {
    if result.isHealthy {
        return (.ok, 0)
    } else {
        let newCount = currentFailureCount + 1
        if newCount >= deadThreshold {
            return (.dead, newCount)
        } else {
            return (.flaky, newCount)
        }
    }
}
