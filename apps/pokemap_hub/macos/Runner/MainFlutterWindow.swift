import Cocoa
import FlutterMacOS

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
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.isDartPackageBridgeReady = true
      self?.flushPendingPackagePaths()
      result(nil)
    }
    packageOpenObserver = NotificationCenter.default.addObserver(
      forName: AppDelegate.packageOpenNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.flushPendingPackagePaths()
    }
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
