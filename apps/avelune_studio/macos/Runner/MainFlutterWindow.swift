import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.title = "Avelune Studio"
    self.minSize = NSSize(width: 480, height: 360)
    self.setContentSize(NSSize(width: 1000, height: 720))

    RegisterGeneratedPlugins(registry: flutterViewController)
    StudioProjectAccessBridge.install(on: flutterViewController)
    StudioUpdaterBridge.install(on: flutterViewController)

    super.awakeFromNib()
  }

  deinit {
    StudioUpdaterBridge.uninstall()
    StudioProjectAccessBridge.uninstall()
  }
}
