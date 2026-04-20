import Flutter
import GameController
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate, FlutterStreamHandler {
  private var pendingProjectPickerResult: FlutterResult?
  private var controllerEventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let projectPickerChannel = FlutterMethodChannel(
        name: "playable_runtime_host/project_picker",
        binaryMessenger: controller.binaryMessenger
      )
      projectPickerChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else { return }
        guard call.method == "pickProjectDirectory" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self.presentProjectDirectoryPicker(result: result)
      }

      let controllerInputChannel = FlutterEventChannel(
        name: "playable_runtime_host/game_controller",
        binaryMessenger: controller.binaryMessenger
      )
      controllerInputChannel.setStreamHandler(self)
    }
    configureGameControllerMonitoring()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureGameControllerMonitoring() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleControllerDidConnect(_:)),
      name: .GCControllerDidConnect,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleControllerDidDisconnect(_:)),
      name: .GCControllerDidDisconnect,
      object: nil
    )
    GCController.controllers().forEach(configureController)
  }

  @objc private func handleControllerDidConnect(_ notification: Notification) {
    guard let controller = notification.object as? GCController else {
      return
    }
    configureController(controller)
  }

  @objc private func handleControllerDidDisconnect(_ notification: Notification) {
    // Pas d'événement synthétique au disconnect: le runtime garde le fallback
    // historique si aucune entrée manette n'arrive plus.
  }

  private func configureController(_ controller: GCController) {
    if let extendedGamepad = controller.extendedGamepad {
      bindDirectionalPad(extendedGamepad.dpad)
      bindDirectionalPad(extendedGamepad.leftThumbstick)
      bindButton(extendedGamepad.buttonA, control: "primary")
      bindButton(extendedGamepad.buttonB, control: "secondary")
    }

    if let microGamepad = controller.microGamepad {
      bindDirectionalPad(microGamepad.dpad)
      bindButton(microGamepad.buttonA, control: "primary")
      bindButton(microGamepad.buttonX, control: "secondary")
    }

    controller.controllerPausedHandler = { [weak self] _ in
      self?.emitControllerEvent(["control": "secondary", "phase": "press"])
      self?.emitControllerEvent(["control": "secondary", "phase": "release"])
    }
  }

  private func bindDirectionalPad(_ directionalPad: GCControllerDirectionPad) {
    bindButton(directionalPad.up, control: "up")
    bindButton(directionalPad.down, control: "down")
    bindButton(directionalPad.left, control: "left")
    bindButton(directionalPad.right, control: "right")
  }

  private func bindButton(_ button: GCControllerButtonInput, control: String) {
    button.pressedChangedHandler = { [weak self] _, _, pressed in
      self?.emitControllerEvent(
        ["control": control, "phase": pressed ? "press" : "release"]
      )
    }
  }

  private func emitControllerEvent(_ payload: [String: String]) {
    DispatchQueue.main.async { [weak self] in
      self?.controllerEventSink?(payload)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    controllerEventSink = events
    GCController.controllers().forEach(configureController)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    controllerEventSink = nil
    return nil
  }

  private func presentProjectDirectoryPicker(result: @escaping FlutterResult) {
    if pendingProjectPickerResult != nil {
      result(
        FlutterError(
          code: "busy",
          message: "Une sélection de projet iOS est déjà en cours.",
          details: nil
        )
      )
      return
    }

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.folder],
        asCopy: false
      )
    } else {
      picker = UIDocumentPickerViewController(
        documentTypes: ["public.folder"],
        in: .open
      )
    }

    picker.delegate = self
    picker.allowsMultipleSelection = false
    pendingProjectPickerResult = result
    topViewController()?.present(picker, animated: true)
  }

  private func topViewController() -> UIViewController? {
    var topController = window?.rootViewController
    while let presented = topController?.presentedViewController {
      topController = presented
    }
    return topController
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingProjectPickerResult else {
      return
    }
    defer {
      pendingProjectPickerResult = nil
    }

    guard let selectedDirectoryUrl = urls.first else {
      result(nil)
      return
    }

    do {
      let importedProjectJsonPath = try importSelectedProjectDirectory(
        from: selectedDirectoryUrl
      )
      result(importedProjectJsonPath)
    } catch let error as RuntimeProjectImportError {
      result(
        FlutterError(
          code: error.code,
          message: error.message,
          details: nil
        )
      )
    } catch {
      result(
        FlutterError(
          code: "import_failed",
          message: "Impossible d'importer le projet sélectionné.",
          details: error.localizedDescription
        )
      )
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    guard let result = pendingProjectPickerResult else {
      return
    }
    pendingProjectPickerResult = nil
    result(nil)
  }

  private func importSelectedProjectDirectory(from selectedDirectoryUrl: URL) throws -> String {
    let didAccessSecurityScope = selectedDirectoryUrl.startAccessingSecurityScopedResource()
    defer {
      if didAccessSecurityScope {
        selectedDirectoryUrl.stopAccessingSecurityScopedResource()
      }
    }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(
      atPath: selectedDirectoryUrl.path,
      isDirectory: &isDirectory
    ), isDirectory.boolValue else {
      throw RuntimeProjectImportError.invalidSelection(
        "Le dossier sélectionné n'est pas accessible depuis iOS."
      )
    }

    let sourceProjectJsonUrl = selectedDirectoryUrl.appendingPathComponent(
      "project.json",
      isDirectory: false
    )
    guard FileManager.default.fileExists(atPath: sourceProjectJsonUrl.path) else {
      throw RuntimeProjectImportError.invalidSelection(
        "Le dossier sélectionné ne contient pas de project.json."
      )
    }

    let documentsDirectory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let projectsDirectory = documentsDirectory.appendingPathComponent(
      "playable_projects",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: projectsDirectory,
      withIntermediateDirectories: true
    )

    let projectName = selectedDirectoryUrl.lastPathComponent.isEmpty
      ? "imported_project"
      : selectedDirectoryUrl.lastPathComponent
    let targetDirectoryUrl = projectsDirectory.appendingPathComponent(
      projectName,
      isDirectory: true
    )

    if FileManager.default.fileExists(atPath: targetDirectoryUrl.path) {
      try FileManager.default.removeItem(at: targetDirectoryUrl)
    }

    do {
      try FileManager.default.copyItem(at: selectedDirectoryUrl, to: targetDirectoryUrl)
    } catch {
      throw RuntimeProjectImportError.importFailed(
        "Impossible de copier le projet sélectionné dans l'app."
      )
    }

    let importedProjectJsonUrl = targetDirectoryUrl.appendingPathComponent(
      "project.json",
      isDirectory: false
    )
    guard FileManager.default.fileExists(atPath: importedProjectJsonUrl.path) else {
      throw RuntimeProjectImportError.importFailed(
        "Le projet importé ne contient pas de project.json."
      )
    }

    return importedProjectJsonUrl.path
  }
}

private enum RuntimeProjectImportError: Error {
  case invalidSelection(String)
  case importFailed(String)

  var code: String {
    switch self {
    case .invalidSelection:
      return "invalid_selection"
    case .importFailed:
      return "import_failed"
    }
  }

  var message: String {
    switch self {
    case let .invalidSelection(message), let .importFailed(message):
      return message
    }
  }
}
