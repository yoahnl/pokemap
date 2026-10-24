import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    guard let menu = NSApp.mainMenu?.items.first?.submenu else { return }
    let item = NSMenuItem(title: "Vérifier les mises à jour…", action: #selector(checkForUpdates(_:)), keyEquivalent: "")
    item.target = self
    menu.insertItem(item, at: min(2, menu.numberOfItems))
  }

  @IBAction func checkForUpdates(_ sender: Any?) {
    ConverterUpdaterBridge.requestManualCheck()
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if ConverterUpdaterBridge.shouldBlockTermination { return .terminateCancel }
    return super.applicationShouldTerminate(sender)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
