import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  #if DEBUG
  private var hubPackageChannel: FlutterMethodChannel?
  private var hubPackagePickerActive = false
  #endif

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    #if DEBUG
    installHubRecipePicker(on: flutterViewController)
    #endif

    super.awakeFromNib()
  }

  #if DEBUG
  private func installHubRecipePicker(on controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "app.pokemap.hub/package_open",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "recipe.window_closed", message: "The recipe window closed.", details: nil))
        return
      }
      switch call.method {
      case "ready":
        result(nil)
      case "canSelectPackages":
        result(true)
      case "pickPackage":
        guard !self.hubPackagePickerActive else {
          result(FlutterError(code: "recipe.picker_active", message: "The package picker is already open.", details: nil))
          return
        }
        self.hubPackagePickerActive = true
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["avelunegame"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsOtherFileTypes = false
        panel.beginSheetModal(for: self) { [weak self] response in
          self?.hubPackagePickerActive = false
          result(response == .OK ? panel.url?.path : nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    hubPackageChannel = channel
  }
  #endif
}
