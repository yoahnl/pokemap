import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var renderActivity: NSObjectProtocol?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    renderActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .latencyCritical],
      reason: "PokeMap renders 3D maps on request"
    )
    mainFlutterWindow?.orderFrontRegardless()
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
