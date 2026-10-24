import Cocoa
import FlutterMacOS
import Sparkle

final class ConverterUpdaterBridge: NSObject, SPUUpdaterDelegate {
  private static var shared: ConverterUpdaterBridge?
  private static let feedURL = "https://github.com/yoahnl/pokemap/releases/download/avelune-converter-update-stable/appcast-macos.xml"

  static func install(on controller: FlutterViewController) {
    shared?.detach()
    shared = ConverterUpdaterBridge(controller: controller)
  }

  static func uninstall() {
    shared?.detach()
    shared = nil
  }

  static func requestManualCheck() {
    shared?.channel.invokeMethod("manualCheckRequested", arguments: nil)
  }

  static var shouldBlockTermination: Bool {
    guard let shared else { return false }
    return shared.activeOperationId != nil && !shared.restartAuthorized
  }

  private let channel: FlutterMethodChannel
  private var updater: SPUUpdater?
  private var userDriver: ConverterUpdateUserDriver?
  private var activeOperationId: String?
  private var pendingInstallHandler: (() -> Void)?
  private var pendingCancelHandler: (() -> Void)?
  private var restartAuthorized = false
  private var installHandlerInvoked = false

  private init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: "com.avelune.converter/updates",
      binaryMessenger: controller.engine.binaryMessenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "native_update_unavailable", message: nil, details: nil))
        return
      }
      switch call.method {
      case "openUpdateFlow": self.openUpdateFlow(call.arguments, result: result)
      case "respondToRestart": self.respondToRestart(call.arguments, result: result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var hasTrustedConfiguration: Bool {
    guard Bundle.main.bundleIdentifier == "com.yoahnl.avelune.converter",
      let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
      let decoded = Data(base64Encoded: key), decoded.count == 32,
      decoded.base64EncodedString() == key,
      let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
      feed == feedURL,
      let url = URL(string: feed), url.scheme == "https", url.host == "github.com",
      Bundle.main.object(forInfoDictionaryKey: "SUAllowsAutomaticUpdates") as? Bool == false,
      Bundle.main.object(forInfoDictionaryKey: "SUAutomaticallyUpdate") as? Bool == false,
      Bundle.main.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool == false,
      Bundle.main.object(forInfoDictionaryKey: "SURequireSignedFeed") as? Bool == true,
      Bundle.main.object(forInfoDictionaryKey: "SUVerifyUpdateBeforeExtraction") as? Bool == true,
      Bundle.main.object(forInfoDictionaryKey: "SUSignedFeedFailureExpirationInterval") as? Int == 0
    else { return false }
    return true
  }

  private func openUpdateFlow(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let values = arguments as? [String: Any],
      Set(values.keys) == Set(["operationId"]),
      let operationId = values["operationId"] as? String,
      !operationId.isEmpty, operationId.utf8.count <= 128,
      operationId == operationId.trimmingCharacters(in: .whitespacesAndNewlines)
    else {
      result(FlutterError(code: "invalid_args", message: "Expected {operationId: String}", details: nil))
      return
    }
    guard activeOperationId == nil else {
      result(FlutterError(code: "native_update_busy", message: "Une mise à jour est déjà en cours.", details: nil))
      return
    }
    guard Self.hasTrustedConfiguration else {
      result(FlutterError(code: "native_update_unconfigured", message: "Les mises à jour signées ne sont pas configurées pour cette installation.", details: nil))
      return
    }
    activeOperationId = operationId
    restartAuthorized = false
    installHandlerInvoked = false
    let driver = ConverterUpdateUserDriver(hostBundle: .main, delegate: nil)
    driver.bridge = self
    driver.operationId = operationId
    let candidate = SPUUpdater(hostBundle: .main, applicationBundle: .main, userDriver: driver, delegate: self)
    userDriver = driver
    updater = candidate
    do {
      try candidate.start()
      guard candidate.canCheckForUpdates else {
        finish(kind: "failed", reason: "native_update_busy")
        result(FlutterError(code: "native_update_busy", message: "La session native est indisponible.", details: nil))
        return
      }
      candidate.checkForUpdates()
      result(nil)
    } catch {
      finish(kind: "failed", reason: error.localizedDescription)
      result(FlutterError(code: "native_update_unavailable", message: error.localizedDescription, details: nil))
    }
  }

  private func respondToRestart(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let values = arguments as? [String: Any],
      Set(values.keys) == Set(["operationId", "canRestart"]),
      let operationId = values["operationId"] as? String,
      let canRestart = values["canRestart"] as? Bool
    else {
      result(FlutterError(code: "invalid_args", message: "Expected {operationId: String, canRestart: Bool}", details: nil))
      return
    }
    guard operationId == activeOperationId,
      let installHandler = pendingInstallHandler,
      !installHandlerInvoked
    else {
      result(FlutterError(code: "native_update_stale_operation", message: "La demande de redémarrage n’est plus active.", details: nil))
      return
    }
    if !canRestart {
      finish(kind: "cancelled", reason: "restartDeclined")
      result(nil)
      return
    }
    pendingInstallHandler = nil
    pendingCancelHandler = nil
    installHandlerInvoked = true
    restartAuthorized = true
    result(nil)
    installHandler()
  }

  fileprivate func isCurrent(_ operationId: String) -> Bool {
    activeOperationId == operationId
  }

  fileprivate func requestRestart(operationId: String, install: @escaping () -> Void, cancel: @escaping () -> Void) {
    guard isCurrent(operationId), pendingInstallHandler == nil,
      !installHandlerInvoked, !restartAuthorized else {
      cancel()
      return
    }
    pendingInstallHandler = install
    pendingCancelHandler = cancel
    emit(operationId: operationId, kind: "restartRequested")
  }

  fileprivate func cancel(operationId: String, handler: @escaping () -> Void) {
    guard isCurrent(operationId) else { handler(); return }
    finish(kind: "cancelled", cancellation: handler)
  }

  private func emit(operationId: String, kind: String, reason: String? = nil) {
    var event: [String: Any] = ["operationId": operationId, "kind": kind]
    if let reason { event["reason"] = reason }
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod("updateEvent", arguments: event)
    }
  }

  private func finish(kind: String, reason: String? = nil, cancellation: (() -> Void)? = nil) {
    guard let operationId = activeOperationId else { return }
    let cancel = cancellation ?? pendingCancelHandler
    activeOperationId = nil
    pendingInstallHandler = nil
    pendingCancelHandler = nil
    restartAuthorized = false
    installHandlerInvoked = false
    cancel?()
    updater = nil
    userDriver = nil
    emit(operationId: operationId, kind: kind, reason: reason)
  }

  private func detach() {
    finish(kind: "cancelled", reason: "bridgeDetached")
    channel.setMethodCallHandler(nil)
  }

  func feedURLString(for updater: SPUUpdater) -> String? { Self.feedURL }

  func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
    guard updater === self.updater, activeOperationId != nil, updateCheck == .updates else {
      throw NSError(domain: "com.avelune.converter.updates", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Une action explicite est nécessaire pour mettre à jour Avelune Converter."])
    }
  }

  func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool {
    updater === self.updater && activeOperationId != nil && restartAuthorized
  }

  func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
    guard updater === self.updater else { return }
    finish(kind: "finished", reason: "noUpdate")
  }

  func userDidCancelDownload(_ updater: SPUUpdater) {
    guard updater === self.updater else { return }
    finish(kind: "cancelled")
  }

  func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
    guard updater === self.updater else { return }
    finish(kind: "failed", reason: error.localizedDescription)
  }

  func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
    guard updater === self.updater else { return }
    finish(kind: "failed", reason: error.localizedDescription)
  }

  func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
    guard updater === self.updater, activeOperationId != nil else { return }
    if let error { finish(kind: "failed", reason: error.localizedDescription) }
    else if !restartAuthorized && pendingInstallHandler == nil { finish(kind: "cancelled") }
  }
}

private final class ConverterUpdateUserDriver: SPUStandardUserDriver {
  weak var bridge: ConverterUpdaterBridge?
  var operationId = ""

  override func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
    super.showUpdateFound(with: appcastItem, state: state) { [weak self] choice in
      guard let self, let bridge = self.bridge, bridge.isCurrent(self.operationId) else { reply(.skip); return }
      if state.stage == .installing {
        if choice == .install {
          bridge.requestRestart(operationId: self.operationId,
            install: { reply(.install) }, cancel: { reply(.skip) })
        } else {
          bridge.cancel(operationId: self.operationId, handler: { reply(.skip) })
        }
      } else if choice == .install {
        reply(choice)
      } else {
        bridge.cancel(operationId: self.operationId, handler: { reply(choice) })
      }
    }
  }

  override func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
    super.showReady(toInstallAndRelaunch: { [weak self] choice in
      guard let self, let bridge = self.bridge, bridge.isCurrent(self.operationId) else { reply(.skip); return }
      if choice == .install {
        bridge.requestRestart(operationId: self.operationId,
          install: { reply(.install) }, cancel: { reply(.skip) })
      } else {
        bridge.cancel(operationId: self.operationId, handler: { reply(.skip) })
      }
    })
  }
}
