import AppKit
import ApplicationServices
import Foundation

enum ProbeFailure: Error, CustomStringConvertible {
    case invalidArguments
    case unavailable(String)

    var description: String {
        switch self {
        case .invalidArguments:
            return "Usage: check_studio_native_accessibility <pid> <expected label> [expected label ...]"
        case .unavailable(let reason):
            return reason
        }
    }
}

func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name, &value) == .success else {
        return nil
    }
    return value
}

func setEnhancedInterface(_ app: AXUIElement, enabled: Bool) throws {
    let name = "AXEnhancedUserInterface" as CFString
    let value: CFBoolean = enabled ? kCFBooleanTrue : kCFBooleanFalse
    let status = AXUIElementSetAttributeValue(app, name, value)
    let observed = attribute(app, name) as? Bool
    guard observed == enabled else {
        throw ProbeFailure.unavailable(
            "Could not set the target application's AX interface to \(enabled): \(status.rawValue)"
        )
    }
}

func labels(in root: AXUIElement, deadline: Date) throws -> Set<String> {
    var queue = [root]
    var visited = Set<AXUIElement>()
    var result = Set<String>()
    while let element = queue.popLast() {
        guard Date() < deadline else {
            throw ProbeFailure.unavailable("Accessibility traversal exceeded its deadline")
        }
        guard visited.insert(element).inserted else { continue }
        guard visited.count <= 20_000 else {
            throw ProbeFailure.unavailable("Accessibility tree exceeded the traversal limit")
        }
        for name in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] {
            if let value = attribute(element, name as CFString) as? String {
                result.insert(value)
            }
        }
        if let children = attribute(element, kAXChildrenAttribute as CFString) as? [AXUIElement] {
            queue.append(contentsOf: children)
        }
    }
    return result
}

func awaitLabels(
    _ app: AXUIElement,
    expected: Set<String>,
    visible: Bool,
    process: NSRunningApplication
) throws -> Int {
    let deadline = Date().addingTimeInterval(8)
    var observed = Set<String>()
    repeat {
        guard !process.isTerminated else {
            throw ProbeFailure.unavailable("The target Studio process terminated during AX inspection")
        }
        observed = try labels(in: app, deadline: deadline)
        if visible ? expected.isSubset(of: observed) : expected.isDisjoint(with: observed) {
            return observed.count
        }
        Thread.sleep(forTimeInterval: 0.1)
    } while Date() < deadline
    let missing = expected.subtracting(observed).sorted().joined(separator: ", ")
    throw ProbeFailure.unavailable(
        visible
            ? "Native accessibility labels missing after activation: \(missing)"
            : "Native accessibility remained active after deactivation"
    )
}

do {
    let args = CommandLine.arguments
    guard args.count >= 3, let pid = pid_t(args[1]), pid > 0 else {
        throw ProbeFailure.invalidArguments
    }
    guard AXIsProcessTrusted() else {
        throw ProbeFailure.unavailable("The probe requires an existing macOS accessibility permission")
    }
    guard let process = NSRunningApplication(processIdentifier: pid),
          process.bundleIdentifier == "com.yoahnl.pokemap.editor",
          !process.isTerminated else {
        throw ProbeFailure.unavailable("The PID must identify a running Avelune Studio")
    }
    let app = AXUIElementCreateApplication(pid)
    guard AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.5) == .success else {
        throw ProbeFailure.unavailable("Could not bound the probe's accessibility requests")
    }
    guard let windows = attribute(app, kAXWindowsAttribute as CFString) as? [AXUIElement],
          !windows.isEmpty else {
        throw ProbeFailure.unavailable("The target Studio must expose an accessibility window")
    }
    let enhanced = "AXEnhancedUserInterface" as CFString
    guard let original = attribute(app, enhanced) as? Bool else {
        throw ProbeFailure.unavailable("Could not read the target application's initial AX state")
    }
    defer {
        try? setEnhancedInterface(app, enabled: original)
    }
    let expected = Set(args.dropFirst(2))
    var cycles = [[String: Int]]()
    for cycle in 1...3 {
        try setEnhancedInterface(app, enabled: false)
        let inactive = try awaitLabels(app, expected: expected, visible: false, process: process)
        try setEnhancedInterface(app, enabled: true)
        let active = try awaitLabels(app, expected: expected, visible: true, process: process)
        cycles.append(["cycle": cycle, "inactiveLabels": inactive, "activeLabels": active])
    }
    try setEnhancedInterface(app, enabled: original)
    let receipt: [String: Any] = [
        "status": "passed", "pid": pid, "expectedLabels": expected.sorted(),
        "cycles": cycles, "originalAXState": original, "originalAXStateRestored": true,
    ]
    let data = try JSONSerialization.data(withJSONObject: receipt, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
} catch {
    let data = try! JSONSerialization.data(
        withJSONObject: ["status": "failed", "reason": String(describing: error)],
        options: [.sortedKeys]
    )
    print(String(decoding: data, as: UTF8.self))
    exit(1)
}
