import CoreFoundation
import FlutterMacOS
import Foundation

final class StudioProjectAccessBridge {
  private static let bookmarkKey = "map_editor.last_project_bookmark"
  private static let recentBookmarksKey = "avelune_studio.recent_project_bookmarks"
  private static let recentBookmarkOrderKey = "avelune_studio.recent_project_bookmark_order"
  private static var channel: FlutterMethodChannel?
  private static var activeScopedURL: URL?
  private static var activeRecentScopedURLs = [String: URL]()
  private static let packExportDispatchQueue = DispatchQueue(
    label: "avelune.resource-pack-export-requests")
  private static var packExportWriter = StudioResourcePackExportWriter()
  private static var creationParentURL: URL?

  static func install(on controller: FlutterViewController) {
    uninstall()
    packExportWriter = StudioResourcePackExportWriter()
    let methodChannel = FlutterMethodChannel(
      name: "map_editor/file_access",
      binaryMessenger: controller.engine.binaryMessenger
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "resourcePackExportChoose":
        chooseResourcePackExport(call.arguments, writer: packExportWriter, result: result)
      case "resourcePackExportAppend", "resourcePackExportSeal", "resourcePackExportFinish",
        "resourcePackExportStatus", "resourcePackExportRelease":
        performResourcePackExport(call, writer: packExportWriter, result: result)
      case "resolveLastProjectManifestPath":
        result(resolveLastProjectManifestPath())
      case "activateProjectDirectory":
        result(activateProjectDirectory(call.arguments))
      case "createMcpProjectBookmark":
        result(createMcpProjectBookmark(call.arguments))
      case "rememberProjectDirectory":
        result(rememberProjectDirectory(call.arguments))
      case "chooseProjectCreationParent":
        chooseProjectCreationParent(result)
      case "releaseProjectCreationParent":
        releaseProjectCreationParent()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = methodChannel
  }

  static func uninstall() {
    channel?.setMethodCallHandler(nil)
    channel = nil
    activeScopedURL?.stopAccessingSecurityScopedResource()
    activeScopedURL = nil
    for url in activeRecentScopedURLs.values {
      url.stopAccessingSecurityScopedResource()
    }
    activeRecentScopedURLs.removeAll()
    releaseProjectCreationParent()
    let failures = packExportWriter.close()
    if !failures.isEmpty { NSLog("Avelune export cleanup: %@", failures.joined(separator: "; ")) }
  }

  private static func exportInteger(_ value: Any?) -> Int64? {
    guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
      number.doubleValue.isFinite, number.doubleValue == Double(number.int64Value)
    else { return nil }
    return number.int64Value
  }

  private static func exportError(_ error: Error) -> FlutterError {
    if let error = error as? StudioResourcePackExportWriter.Failure {
      return FlutterError(code: error.code, message: error.message, details: nil)
    }
    return FlutterError(
      code: "resource_pack.export_failed", message: error.localizedDescription, details: nil)
  }

  private static func chooseResourcePackExport(
    _ arguments: Any?, writer: StudioResourcePackExportWriter, result: @escaping FlutterResult
  ) {
    guard let input = arguments as? [String: Any], let name = input["suggestedName"] as? String,
      let length = exportInteger(input["byteLength"]), let hash = input["rawSha256"] as? String
    else {
      result(
        FlutterError(
          code: "resource_pack.export_input_invalid",
          message: "La description de l’export est invalide.", details: nil))
      return
    }
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    panel.prompt = "Exporter ici"
    panel.message = "Choisissez le dossier de destination du pack « \(name) »."
    panel.begin { response in
      guard response == .OK, let folder = panel.url else {
        result(nil)
        return
      }
      do {
        let output = try writer.choose(
          folder: folder, name: name, byteLength: length, rawSha256: hash
        ) { destination in
          let confirmation = NSAlert()
          confirmation.messageText = "Remplacer « \(destination.lastPathComponent) » ?"
          confirmation.informativeText =
            "Le fichier existant dans \(destination.deletingLastPathComponent().path) sera remplacé par ce pack."
          confirmation.addButton(withTitle: "Remplacer")
          confirmation.addButton(withTitle: "Annuler")
          return confirmation.runModal() == .alertFirstButtonReturn
        }
        result(output)
      } catch { result(exportError(error)) }
    }
  }

  private static func performResourcePackExport(
    _ call: FlutterMethodCall, writer: StudioResourcePackExportWriter,
    result: @escaping FlutterResult
  ) {
    guard let input = call.arguments as? [String: Any], let token = input["token"] as? String,
      !token.isEmpty, token.utf8.count <= 128
    else {
      result(
        FlutterError(
          code: "resource_pack.export_input_invalid", message: "La session d’export est invalide.",
          details: nil))
      return
    }
    packExportDispatchQueue.async {
      do {
        let output: [String: Any]
        switch call.method {
        case "resourcePackExportAppend":
          guard let offset = exportInteger(input["offset"]),
            let bytes = input["bytes"] as? FlutterStandardTypedData
          else {
            throw StudioResourcePackExportWriter.Failure(
              code: "resource_pack.export_input_invalid", message: "Le bloc d’export est invalide.")
          }
          output = try writer.append(token: token, offset: offset, bytes: bytes.data)
        case "resourcePackExportSeal": output = try writer.seal(token: token)
        case "resourcePackExportFinish": output = try writer.finish(token: token)
        case "resourcePackExportStatus": output = try writer.status(token: token)
        case "resourcePackExportRelease": output = try writer.release(token: token)
        default:
          throw StudioResourcePackExportWriter.Failure(
            code: "resource_pack.export_input_invalid",
            message: "L’opération d’export est inconnue.")
        }
        DispatchQueue.main.async { result(output) }
      } catch { DispatchQueue.main.async { result(exportError(error)) } }
    }
  }

  private static func chooseProjectCreationParent(_ result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    panel.prompt = "Choisir"
    panel.message = "Choisissez le dossier parent du nouveau projet Avelune."
    panel.begin { response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      let authorized = url.startAccessingSecurityScopedResource()
      releaseProjectCreationParent()
      if authorized { creationParentURL = url }
      result(url.path)
    }
  }

  private static func releaseProjectCreationParent() {
    creationParentURL?.stopAccessingSecurityScopedResource()
    creationParentURL = nil
  }

  private static func activateProjectDirectory(_ arguments: Any?) -> Bool {
    guard let directoryURL = projectDirectoryURL(from: arguments) else {
      return false
    }
    let path = directoryURL.path
    let defaults = UserDefaults.standard
    guard
      let bookmarks = defaults.dictionary(forKey: recentBookmarksKey) as? [String: Data],
      let bookmarkData = bookmarks[path]
    else {
      return false
    }

    var bookmarkIsStale = false
    do {
      let scopedURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &bookmarkIsStale
      )
      guard scopedURL.standardizedFileURL == directoryURL else {
        return false
      }

      if activeRecentScopedURLs[path] == nil && activeScopedURL?.standardizedFileURL != directoryURL {
        guard scopedURL.startAccessingSecurityScopedResource() else {
          return false
        }
        activeRecentScopedURLs[path] = scopedURL
      }

      if bookmarkIsStale {
        let refreshedData = try scopedURL.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        var refreshedBookmarks = bookmarks
        refreshedBookmarks[path] = refreshedData
        defaults.set(refreshedBookmarks, forKey: recentBookmarksKey)
      }
      return true
    } catch {
      return false
    }
  }

  private static func createMcpProjectBookmark(_ arguments: Any?) -> String? {
    guard let directory = projectDirectoryURL(from: arguments) else { return nil }
    let scoped = activeRecentScopedURLs[directory.path] ??
      (activeScopedURL?.standardizedFileURL == directory ? activeScopedURL : nil)
    guard let scoped else { return nil }
    do {
      return try scoped.bookmarkData(options: [], includingResourceValuesForKeys: nil,
        relativeTo: nil).base64EncodedString()
    } catch { return nil }
  }

  private static func rememberProjectDirectory(_ arguments: Any?) -> Bool {
    guard let directoryURL = projectDirectoryURL(from: arguments) else {
      return false
    }
    var isDirectory = ObjCBool(false)
    guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return false
    }

    do {
      let bookmarkData = try directoryURL.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      let defaults = UserDefaults.standard
      var bookmarks = defaults.dictionary(forKey: recentBookmarksKey) as? [String: Data] ?? [:]
      var order = defaults.stringArray(forKey: recentBookmarkOrderKey) ?? []
      order.removeAll { $0 == directoryURL.path }
      order.insert(directoryURL.path, at: 0)
      order = Array(order.prefix(5))
      let retainedPaths = Set(order)
      bookmarks[directoryURL.path] = bookmarkData
      bookmarks = bookmarks.filter { retainedPaths.contains($0.key) }
      defaults.set(bookmarks, forKey: recentBookmarksKey)
      defaults.set(order, forKey: recentBookmarkOrderKey)
      for path in Array(activeRecentScopedURLs.keys) where !retainedPaths.contains(path) {
        activeRecentScopedURLs.removeValue(forKey: path)?.stopAccessingSecurityScopedResource()
      }
      return true
    } catch {
      return false
    }
  }

  private static func projectDirectoryURL(from arguments: Any?) -> URL? {
    guard
      let path = (arguments as? [String: Any])?["path"] as? String,
      (path as NSString).isAbsolutePath
    else {
      return nil
    }
    return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
  }

  private static func resolveLastProjectManifestPath() -> String? {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
      return nil
    }

    var bookmarkIsStale = false
    do {
      let projectDirectoryURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &bookmarkIsStale
      )

      if bookmarkIsStale {
        let refreshedData = try projectDirectoryURL.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        UserDefaults.standard.set(refreshedData, forKey: bookmarkKey)
      }

      if activeScopedURL?.standardizedFileURL != projectDirectoryURL.standardizedFileURL {
        guard projectDirectoryURL.startAccessingSecurityScopedResource() else {
          return nil
        }
        activeScopedURL?.stopAccessingSecurityScopedResource()
        activeScopedURL = projectDirectoryURL
      }

      return projectDirectoryURL.appendingPathComponent("project.json").path
    } catch {
      return nil
    }
  }
}
