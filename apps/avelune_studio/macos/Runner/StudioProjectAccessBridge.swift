import Foundation
import FlutterMacOS

final class StudioProjectAccessBridge {
  private static let bookmarkKey = "map_editor.last_project_bookmark"
  private static let recentBookmarksKey = "avelune_studio.recent_project_bookmarks"
  private static let recentBookmarkOrderKey = "avelune_studio.recent_project_bookmark_order"
  private static var channel: FlutterMethodChannel?
  private static var activeScopedURL: URL?
  private static var activeRecentScopedURLs = [String: URL]()

  static func install(on controller: FlutterViewController) {
    uninstall()
    let methodChannel = FlutterMethodChannel(
      name: "map_editor/file_access",
      binaryMessenger: controller.engine.binaryMessenger
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "resolveLastProjectManifestPath":
        result(resolveLastProjectManifestPath())
      case "activateProjectDirectory":
        result(activateProjectDirectory(call.arguments))
      case "rememberProjectDirectory":
        result(rememberProjectDirectory(call.arguments))
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
