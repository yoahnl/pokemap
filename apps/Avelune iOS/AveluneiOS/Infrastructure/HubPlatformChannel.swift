import Flutter
import Foundation

/// Answers the platform services the shared runtime expects from its host.
///
/// The runtime asks the host for storage capacity before staging a package;
/// the Flutter app answers on this same channel, so the contract is shared.
@MainActor
final class HubPlatformChannel {
    private let channel: FlutterMethodChannel

    init(engine: FlutterEngine) {
        channel = FlutterMethodChannel(
            name: "com.yoahnl.avelune.player/ios",
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "availableDiskBytes":
                Self.reportAvailableDiskBytes(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func reportAvailableDiskBytes(result: FlutterResult) {
        do {
            let supportDirectory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let values = try supportDirectory.resourceValues(
                forKeys: [
                    .volumeAvailableCapacityForImportantUsageKey,
                    .volumeAvailableCapacityKey,
                ]
            )
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                result(NSNumber(value: capacity))
            } else if let capacity = values.volumeAvailableCapacity {
                result(NSNumber(value: capacity))
            } else {
                result(
                    FlutterError(
                        code: "diskCapacityUnavailable",
                        message: "Available storage capacity could not be determined.",
                        details: nil
                    )
                )
            }
        } catch {
            result(
                FlutterError(
                    code: "diskCapacityFailed",
                    message: "Available storage capacity could not be read.",
                    details: error.localizedDescription
                )
            )
        }
    }
}
