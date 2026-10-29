import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "PokeMap 3D render"
    self.setContentSize(NSSize(width: 800, height: 450))
    self.styleMask.remove(.resizable)
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    if let screen = NSScreen.main?.visibleFrame {
      self.setFrameOrigin(NSPoint(x: screen.maxX - self.frame.width - 24, y: screen.minY + 24))
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
