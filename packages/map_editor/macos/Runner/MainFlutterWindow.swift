import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    MacOsFileAccessBridge.install(on: flutterViewController)

    super.awakeFromNib()
  }
}

/// macOS sandbox helper for persistent access to user-selected project folders.
///
/// Why this bridge exists:
/// - The editor remembers last opened project.
/// - Under macOS sandbox, remembering only a file path is not enough across app
///   launches for Desktop/Documents folders.
/// - Security-scoped bookmarks are the canonical solution to persist the grant.
final class MacOsFileAccessBridge {
  private static let channelName = "map_editor/file_access"
  private static let bookmarkKey = "map_editor.last_project_bookmark"
  private static var activeScopedURL: URL?

  static func install(on controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "rememberProjectPath":
        guard
          let args = call.arguments as? [String: Any],
          let manifestPath = args["manifestPath"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Expected {manifestPath: String}",
              details: nil
            )
          )
          return
        }
        rememberProjectPath(manifestPath: manifestPath, result: result)

      case "resolveLastProjectManifestPath":
        resolveLastProjectManifestPath(result: result)

      case "clearRememberedProjectPath":
        clearRememberedProjectPath(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func rememberProjectPath(
    manifestPath: String,
    result: @escaping FlutterResult
  ) {
    let manifestURL = URL(fileURLWithPath: manifestPath)
    let projectDirectoryURL = manifestURL.deletingLastPathComponent()

    do {
      let bookmarkData = try projectDirectoryURL.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
      result(true)
    } catch {
      result(
        FlutterError(
          code: "bookmark_create_failed",
          message: "Failed to create security-scoped bookmark.",
          details: error.localizedDescription
        )
      )
    }
  }

  private static func resolveLastProjectManifestPath(result: @escaping FlutterResult) {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
      result(nil)
      return
    }

    var bookmarkIsStale = false
    do {
      let projectDirectoryURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &bookmarkIsStale
      )

      // Refresh stale bookmarks defensively so the next launch keeps working.
      if bookmarkIsStale {
        let refreshedData = try projectDirectoryURL.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        UserDefaults.standard.set(refreshedData, forKey: bookmarkKey)
      }

      guard projectDirectoryURL.startAccessingSecurityScopedResource() else {
        result(nil)
        return
      }

      // Release previously active scope to avoid leaking scoped sessions.
      if let previousURL = activeScopedURL, previousURL != projectDirectoryURL {
        previousURL.stopAccessingSecurityScopedResource()
      }
      activeScopedURL = projectDirectoryURL

      let manifestURL = projectDirectoryURL.appendingPathComponent("project.json")
      result(manifestURL.path)
    } catch {
      result(nil)
    }
  }

  private static func clearRememberedProjectPath(result: @escaping FlutterResult) {
    UserDefaults.standard.removeObject(forKey: bookmarkKey)
    if let previousURL = activeScopedURL {
      previousURL.stopAccessingSecurityScopedResource()
      activeScopedURL = nil
    }
    result(true)
  }
}
