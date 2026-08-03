import Cocoa
import FlutterMacOS
import Sparkle

/// Owns Sparkle's single updater instance and keeps every restart behind the
/// same Dart readiness gate used by the rest of the editor.
final class EditorUpdaterBridge: NSObject, SPUUpdaterDelegate {
  private static var shared: EditorUpdaterBridge?

  static func install(on controller: FlutterViewController) {
    shared?.detach()
    shared = EditorUpdaterBridge(controller: controller)
  }

  static func uninstall() {
    shared?.detach()
    shared = nil
  }

  static func requestManualCheck() {
    shared?.channel.invokeMethod("manualCheckRequested", arguments: nil)
  }

  fileprivate let channel: FlutterMethodChannel
  private var updaterController: SPUStandardUpdaterController?
  private var activeOperationId: String?
  private var pendingInstallHandler: (() -> Void)?
  private var restartReady = false

  private init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: "map_editor/editor_updates",
      binaryMessenger: controller.engine.binaryMessenger
    )
    super.init()

    if Self.hasTrustedConfiguration {
      updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
      )
    }

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private static var hasTrustedConfiguration: Bool {
    guard
      let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
      !key.isEmpty,
      !key.contains("$("),
      let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
      let url = URL(string: feed),
      url.scheme == "https"
    else {
      return false
    }
    return true
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openExternalUri":
      result(openTrustedExternalUri(call.arguments))
    case "openUpdateFlow":
      openUpdateFlow(call.arguments, result: result)
    case "setRestartReady":
      guard let canRestart = boolArgument("canRestart", from: call.arguments) else {
        result(invalidArgumentsError("Expected {canRestart: bool}"))
        return
      }
      restartReady = canRestart
      result(nil)
    case "respondToRestart":
      respondToRestart(call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openUpdateFlow(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let operationId = stringArgument("operationId", from: arguments),
      !operationId.isEmpty
    else {
      result(invalidArgumentsError("Expected {operationId: String}"))
      return
    }
    guard let updaterController else {
      result(
        FlutterError(
          code: "native_update_unconfigured",
          message: "Sparkle has no release public key configured.",
          details: nil
        )
      )
      return
    }

    if pendingInstallHandler != nil {
      activeOperationId = operationId
      emit(kind: "restartRequested")
      result(nil)
      return
    }
    guard updaterController.updater.canCheckForUpdates else {
      result(
        FlutterError(
          code: "native_update_busy",
          message: "Sparkle is already handling an update.",
          details: nil
        )
      )
      return
    }
    activeOperationId = operationId
    updaterController.checkForUpdates(nil)
    result(nil)
  }

  private func respondToRestart(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let operationId = stringArgument("operationId", from: arguments),
      operationId == activeOperationId,
      let canRestart = boolArgument("canRestart", from: arguments)
    else {
      result(invalidArgumentsError("Expected the active operation and canRestart"))
      return
    }

    restartReady = canRestart
    if canRestart, let installHandler = pendingInstallHandler {
      pendingInstallHandler = nil
      installHandler()
    }
    result(nil)
  }

  private func openTrustedExternalUri(_ arguments: Any?) -> Bool {
    guard
      let rawUri = stringArgument("uri", from: arguments),
      let uri = URL(string: rawUri),
      uri.scheme == "https",
      uri.host == "github.com"
    else {
      return false
    }
    return NSWorkspace.shared.open(uri)
  }

  private func stringArgument(_ key: String, from arguments: Any?) -> String? {
    (arguments as? [String: Any])?[key] as? String
  }

  private func boolArgument(_ key: String, from arguments: Any?) -> Bool? {
    (arguments as? [String: Any])?[key] as? Bool
  }

  private func invalidArgumentsError(_ message: String) -> FlutterError {
    FlutterError(code: "invalid_args", message: message, details: nil)
  }

  private func emit(kind: String) {
    guard let operationId = activeOperationId else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod(
        "updateEvent",
        arguments: ["kind": kind, "operationId": operationId]
      )
    }
  }

  private func emitTerminal(kind: String) {
    emit(kind: kind)
    activeOperationId = nil
  }

  private func detach() {
    channel.setMethodCallHandler(nil)
    pendingInstallHandler = nil
    activeOperationId = nil
    updaterController = nil
  }

  func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
    emitTerminal(kind: "noUpdate")
  }

  func userDidCancelDownload(_ updater: SPUUpdater) {
    emitTerminal(kind: "cancelled")
  }

  func updater(
    _ updater: SPUUpdater,
    failedToDownloadUpdate item: SUAppcastItem,
    error: Error
  ) {
    emitTerminal(kind: "failed")
  }

  func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
    emit(kind: "installing")
  }

  func updater(
    _ updater: SPUUpdater,
    shouldPostponeRelaunchForUpdate item: SUAppcastItem,
    untilInvokingBlock installHandler: @escaping () -> Void
  ) -> Bool {
    pendingInstallHandler = installHandler
    emit(kind: "restartRequested")
    return true
  }

  func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
    emitTerminal(kind: "failed")
  }
}
