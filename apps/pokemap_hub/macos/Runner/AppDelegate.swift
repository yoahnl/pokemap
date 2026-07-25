import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static let packageOpenNotification = Notification.Name(
    "app.pokemap.hub.package-open"
  )

  private var pendingPackagePaths: [String] = []

  override func application(
    _ sender: NSApplication,
    openFiles filenames: [String]
  ) {
    pendingPackagePaths.append(contentsOf: filenames)
    NotificationCenter.default.post(
      name: Self.packageOpenNotification,
      object: nil
    )
    sender.reply(toOpenOrPrint: .success)
  }

  func takePendingPackagePaths() -> [String] {
    defer { pendingPackagePaths.removeAll() }
    return pendingPackagePaths
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
