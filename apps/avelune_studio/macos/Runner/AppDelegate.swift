import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    DispatchQueue.main.async { [weak self] in
      self?.migrateInstalledBundleNameIfNeeded()
    }
    super.applicationDidFinishLaunching(notification)
  }

  @IBAction func checkForUpdates(_ sender: Any?) {
    StudioUpdaterBridge.requestManualCheck()
  }

  private func migrateInstalledBundleNameIfNeeded() {
    let installedBundle = Bundle.main.bundleURL
    guard installedBundle.lastPathComponent == "PokeMap.app",
          Bundle.main.bundleIdentifier == "com.yoahnl.pokemap.editor",
          !installedBundle.path.contains("/AppTranslocation/") else {
      return
    }

    let renamedBundle = installedBundle.deletingLastPathComponent()
      .appendingPathComponent("Avelune Studio.app", isDirectory: true)
    guard !FileManager.default.fileExists(atPath: renamedBundle.path) else {
      return
    }

    let installedDirectory = installedBundle.deletingLastPathComponent()
    if (try? installedDirectory.resourceValues(forKeys: [.volumeIsReadOnlyKey]))?.volumeIsReadOnly == true {
      return
    }

    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.allowsMultipleSelection = false
    panel.directoryURL = installedDirectory
    panel.prompt = "Autoriser"
    panel.message = "Sélectionne le dossier contenant PokeMap.app pour le renommer en Avelune Studio.app."
    panel.begin { [weak self] response in
      guard response == .OK,
            let authorizedDirectory = panel.url,
            authorizedDirectory.standardizedFileURL == installedDirectory.standardizedFileURL else {
        return
      }
      self?.renameAndRelaunch(
        installedBundle: installedBundle,
        renamedBundle: renamedBundle,
        authorizedDirectory: authorizedDirectory
      )
    }
  }

  private func renameAndRelaunch(
    installedBundle: URL,
    renamedBundle: URL,
    authorizedDirectory: URL
  ) {
    let hasSecurityScope = authorizedDirectory.startAccessingSecurityScopedResource()
    do {
      try FileManager.default.moveItem(at: installedBundle, to: renamedBundle)
    } catch {
      if hasSecurityScope {
        authorizedDirectory.stopAccessingSecurityScopedResource()
      }
      NSLog("Unable to rename the installed Avelune Studio bundle: %@", String(describing: error))
      return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    NSWorkspace.shared.openApplication(at: renamedBundle, configuration: configuration) { application, error in
      if application == nil {
        do {
          try FileManager.default.moveItem(at: renamedBundle, to: installedBundle)
        } catch {
          NSLog("Unable to restore the installed bundle after relaunch failed: %@", String(describing: error))
        }
        NSLog("Unable to relaunch Avelune Studio after renaming: %@", String(describing: error))
      } else {
        NSApp.terminate(nil)
      }
      if hasSecurityScope {
        authorizedDirectory.stopAccessingSecurityScopedResource()
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
