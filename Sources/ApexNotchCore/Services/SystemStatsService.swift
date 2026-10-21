import Foundation
import IOKit.ps
import Darwin

public struct SystemStats {
    public var cpuUsagePercent: Double = 0.0
    public var memoryUsedBytes: UInt64 = 0
    public var memoryTotalBytes: UInt64 = 0
    public var memoryPercent: Double = 0.0
    public var diskFreeBytes: UInt64 = 0
    public var diskTotalBytes: UInt64 = 0
    public var diskUsedPercent: Double = 0.0
    public var batteryLevel: Int = 100
    public var isCharging: Bool = false
    public var isPluggedIn: Bool = false
}

@MainActor
public final class SystemStatsService: ObservableObject {
    public static let shared = SystemStatsService()
    
    @Published public private(set) var stats = SystemStats()
    
    private var timer: Timer?
    private var previousCPULoad: processor_cpu_load_info?
    private var previousCPUTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) = (0, 0, 0, 0)
    
    private init() {
        refresh()
    }
    
    public func startMonitoring() {
        guard timer == nil else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    public func refresh() {
        updateCPU()
        updateMemory()
        updateDisk()
        updateBattery()
    }
    
    // MARK: - CPU Load
    private func updateCPU() {
        var count: mach_msg_type_number_t = 0
        var cpuInfo: processor_info_array_t?
        var numProcessors: natural_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numProcessors,
            &cpuInfo,
            &count
        )
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }
        
        var totalUser: UInt32 = 0
        var totalSystem: UInt32 = 0
        var totalIdle: UInt32 = 0
        var totalNice: UInt32 = 0
        
        for i in 0..<Int(numProcessors) {
            let offset = i * Int(CPU_STATE_MAX)
            let user = UInt32(cpuInfo[offset + Int(CPU_STATE_USER)])
            let sys = UInt32(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt32(cpuInfo[offset + Int(CPU_STATE_NICE)])
            
            totalUser += user
            totalSystem += sys
            totalIdle += idle
            totalNice += nice
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(count * 4))
        
        let userDiff = totalUser >= previousCPUTicks.user ? totalUser - previousCPUTicks.user : 0
        let sysDiff = totalSystem >= previousCPUTicks.system ? totalSystem - previousCPUTicks.system : 0
        let idleDiff = totalIdle >= previousCPUTicks.idle ? totalIdle - previousCPUTicks.idle : 0
        let niceDiff = totalNice >= previousCPUTicks.nice ? totalNice - previousCPUTicks.nice : 0
        
        previousCPUTicks = (totalUser, totalSystem, totalIdle, totalNice)
        
        let totalTicks = Double(userDiff + sysDiff + idleDiff + niceDiff)
        if totalTicks > 0 {
            let usage = (Double(userDiff + sysDiff + niceDiff) / totalTicks) * 100.0
            stats.cpuUsagePercent = min(max(usage, 0.0), 100.0)
        }
    }
    
    // MARK: - Memory
    private func updateMemory() {
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStat = vm_statistics64()
        
        let hostPort = mach_host_self()
        let kern = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }
        
        if kern == KERN_SUCCESS {
            let pageSize = UInt64(getpagesize())
            let active = UInt64(vmStat.active_count) * pageSize
            let wired = UInt64(vmStat.wire_count) * pageSize
            let compressed = UInt64(vmStat.compressor_page_count) * pageSize
            
            let used = active + wired + compressed
            let total = ProcessInfo.processInfo.physicalMemory
            
            stats.memoryUsedBytes = used
            stats.memoryTotalBytes = total
            if total > 0 {
                stats.memoryPercent = (Double(used) / Double(total)) * 100.0
            }
        }
    }
    
    // MARK: - Disk
    private func updateDisk() {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            let total = (attrs[.systemSize] as? NSNumber)?.uint64Value ?? 0
            let free = (attrs[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            
            stats.diskTotalBytes = total
            stats.diskFreeBytes = free
            if total > 0 {
                let used = total - free
                stats.diskUsedPercent = (Double(used) / Double(total)) * 100.0
            }
        }
    }
    
    // MARK: - Battery
    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else {
            stats.batteryLevel = 100
            stats.isCharging = false
            stats.isPluggedIn = true
            return
        }
        
        if let current = desc[kIOPSCurrentCapacityKey as String] as? Int {
            stats.batteryLevel = current
        }
        if let isCharging = desc[kIOPSIsChargingKey as String] as? Bool {
            stats.isCharging = isCharging
        }
        if let powerSourceState = desc[kIOPSPowerSourceStateKey as String] as? String {
            stats.isPluggedIn = (powerSourceState == (kIOPSACPowerValue as String))
        }
    }
}
