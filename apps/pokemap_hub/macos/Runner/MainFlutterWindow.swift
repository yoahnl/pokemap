import Cocoa
import FlutterMacOS
import Security
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  private var packageOpenChannel: FlutterMethodChannel?
  private var packageOpenObserver: NSObjectProtocol?
  private var isDartPackageBridgeReady = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    configurePackageOpenBridge(flutterViewController)

    super.awakeFromNib()
  }

  deinit {
    if let observer = packageOpenObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  private func configurePackageOpenBridge(
    _ flutterViewController: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "app.pokemap.hub/package_open",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    packageOpenChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "ready":
        self?.isDartPackageBridgeReady = true
        self?.flushPendingPackagePaths()
        result(nil)
      case "canSelectPackages":
        result(Self.hasUserSelectedFileReadEntitlement())
      case "pickPackage":
        guard let self = self else {
          result(
            FlutterError(
              code: "picker.windowUnavailable",
              message: "The Hub window is unavailable.",
              details: nil
            )
          )
          return
        }
        self.presentPackagePicker(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    packageOpenObserver = NotificationCenter.default.addObserver(
      forName: AppDelegate.packageOpenNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.flushPendingPackagePaths()
    }
  }

  private func presentPackagePicker(_ result: @escaping FlutterResult) {
    guard let packageType = UTType(filenameExtension: "avelunegame") else {
      result(
        FlutterError(
          code: "picker.typeUnavailable",
          message: "The Avelune game package type is unavailable.",
          details: nil
        )
      )
      return
    }
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [packageType]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.prompt = "Importer"
    panel.message = "Sélectionnez un jeu Avelune au format .avelunegame."
    panel.beginSheetModal(for: self) { response in
      guard response == .OK else {
        result(nil)
        return
      }
      result(panel.url?.path)
    }
  }

  private static func hasUserSelectedFileReadEntitlement() -> Bool {
    guard
      let task = SecTaskCreateFromSelf(nil),
      let value = SecTaskCopyValueForEntitlement(
        task,
        "com.apple.security.files.user-selected.read-only" as CFString,
        nil
      )
    else {
      return false
    }
    return (value as? Bool) == true
  }

  private func flushPendingPackagePaths() {
    guard isDartPackageBridgeReady,
          let delegate = NSApp.delegate as? AppDelegate else {
      return
    }
    let paths = delegate.takePendingPackagePaths()
    guard !paths.isEmpty else { return }
    packageOpenChannel?.invokeMethod("openPackages", arguments: paths)
  }
}
