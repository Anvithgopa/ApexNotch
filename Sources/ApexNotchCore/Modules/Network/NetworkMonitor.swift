import Foundation
import Combine

public struct NetworkSpeedSnapshot {
    public var bytesInPerSec: Double = 0.0
    public var bytesOutPerSec: Double = 0.0
    public var totalBytesIn: UInt64 = 0
    public var totalBytesOut: UInt64 = 0
    public var formattedDownload: String { NetworkMonitor.formatSpeed(bytesInPerSec) }
    public var formattedUpload: String { NetworkMonitor.formatSpeed(bytesOutPerSec) }
}

@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public private(set) var currentSpeed = NetworkSpeedSnapshot()
    @Published public private(set) var downloadHistory: [Double] = Array(repeating: 0.0, count: 20)
    @Published public private(set) var uploadHistory: [Double] = Array(repeating: 0.0, count: 20)
    
    private var timer: Timer?
    private var lastSampleTime: Date = Date()
    private var lastTotalIn: UInt64 = 0
    private var lastTotalOut: UInt64 = 0
    
    private init() {}
    
    public func startMonitoring() {
        guard timer == nil else { return }
        
        let (initialIn, initialOut) = fetchTotalBytes()
        lastTotalIn = initialIn
        lastTotalOut = initialOut
        lastSampleTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sample()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func sample() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSampleTime)
        guard elapsed > 0.5 else { return }
        
        let (currentIn, currentOut) = fetchTotalBytes()
        
        let deltaIn = currentIn >= lastTotalIn ? currentIn - lastTotalIn : 0
        let deltaOut = currentOut >= lastTotalOut ? currentOut - lastTotalOut : 0
        
        let speedIn = Double(deltaIn) / elapsed
        let speedOut = Double(deltaOut) / elapsed
        
        lastTotalIn = currentIn
        lastTotalOut = currentOut
        lastSampleTime = now
        
        currentSpeed = NetworkSpeedSnapshot(
            bytesInPerSec: speedIn,
            bytesOutPerSec: speedOut,
            totalBytesIn: currentIn,
            totalBytesOut: currentOut
        )
        
        // Update history sparkline
        downloadHistory.append(speedIn)
        if downloadHistory.count > 20 { downloadHistory.removeFirst() }
        
        uploadHistory.append(speedOut)
        if uploadHistory.count > 20 { uploadHistory.removeFirst() }
    }
    
    private func fetchTotalBytes() -> (UInt64, UInt64) {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return (0, 0) }
        defer { freeifaddrs(ifap) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if isUp && !isLoopback, let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = current.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(networkData.pointee.ifi_ibytes)
                    totalOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            cursor = current.pointee.ifa_next
        }
        
        return (totalIn, totalOut)
    }
    
    public nonisolated static func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_048_576.0 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576.0)
        } else if bytesPerSec >= 1024.0 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024.0)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }
}
