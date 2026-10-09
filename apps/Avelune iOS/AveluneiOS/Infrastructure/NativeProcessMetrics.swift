import Darwin
import Foundation

enum NativeProcessMetrics {
    static func read() -> [String: Any] {
        let process = ProcessInfo.processInfo
        var sample: [String: Any] = [
            "uptimeSeconds": process.systemUptime,
            "memoryKind": "footprint",
            "thermalState": thermalState(process.thermalState),
            "lowPowerMode": process.isLowPowerModeEnabled
        ]
        var usage = rusage()
        if getrusage(RUSAGE_SELF, &usage) == 0 {
            sample["cpuSeconds"] = seconds(usage.ru_utime) + seconds(usage.ru_stime)
        }
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            sample["memoryBytes"] = info.phys_footprint
        }
        return sample
    }

    private static func seconds(_ time: timeval) -> Double {
        Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000
    }

    private static func thermalState(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}
