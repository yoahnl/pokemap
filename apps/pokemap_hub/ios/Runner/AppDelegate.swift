import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIDocumentPickerDelegate
{
  private var hubChannel: FlutterMethodChannel?
  private var pendingPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "app.pokemap.hub/ios",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "hubUnavailable",
            message: "PokeMap Hub is no longer available.",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "pickPackage":
        self.presentPackagePicker(result: result)
      case "availableDiskBytes":
        self.reportAvailableDiskBytes(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    hubChannel = channel
  }

  private func presentPackagePicker(result: @escaping FlutterResult) {
    guard pendingPickerResult == nil else {
      result(
        FlutterError(
          code: "pickerAlreadyOpen",
          message: "A package picker is already open.",
          details: nil
        )
      )
      return
    }
    guard let presenter = activeViewController() else {
      result(
        FlutterError(
          code: "missingPresenter",
          message: "The package picker has no active window.",
          details: nil
        )
      )
      return
    }

    let packageType =
      UTType(filenameExtension: "pokemapgame", conformingTo: .data) ?? .data
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [packageType],
      asCopy: true
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    pendingPickerResult = result
    presenter.present(picker, animated: true)
  }

  private func reportAvailableDiskBytes(result: FlutterResult) {
    do {
      let supportDirectory = try FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let values = try supportDirectory.resourceValues(
        forKeys: [
          .volumeAvailableCapacityForImportantUsageKey,
          .volumeAvailableCapacityKey,
        ]
      )
      if let capacity = values.volumeAvailableCapacityForImportantUsage {
        result(NSNumber(value: capacity))
        return
      }
      if let capacity = values.volumeAvailableCapacity {
        result(NSNumber(value: capacity))
        return
      }
      result(
        FlutterError(
          code: "diskCapacityUnavailable",
          message: "Available storage capacity could not be determined.",
          details: nil
        )
      )
    } catch {
      result(
        FlutterError(
          code: "diskCapacityFailed",
          message: "Available storage capacity could not be read.",
          details: error.localizedDescription
        )
      )
    }
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    finishPackagePicker(with: urls.first?.path)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishPackagePicker(with: nil)
  }

  private func finishPackagePicker(with selectedPath: String?) {
    let result = pendingPickerResult
    pendingPickerResult = nil
    result?(selectedPath)
  }

  private func activeViewController() -> UIViewController? {
    let activeScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    let activeWindow = activeScenes
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
      ?? activeScenes.flatMap(\.windows).first
    return topViewController(from: activeWindow?.rootViewController)
  }

  private func topViewController(
    from root: UIViewController?
  ) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tabs = root as? UITabBarController {
      return topViewController(from: tabs.selectedViewController)
    }
    return root
  }
}
