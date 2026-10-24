import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  override func close() {
    if ConverterUpdaterBridge.shouldBlockTermination { return }
    super.close()
  }

  deinit {
    ConverterUpdaterBridge.uninstall()
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "Avelune Converter"
    self.contentMinSize = NSSize(width: 1280, height: 800)
    self.setContentSize(NSSize(width: 1600, height: 1000))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    ConverterUpdaterBridge.install(on: flutterViewController)

    let secrets = FlutterMethodChannel(
      name: "com.avelune.converter/vision_secret",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    secrets.setMethodCallHandler { call, result in
      guard let bundleId = Bundle.main.bundleIdentifier else {
        result(FlutterError(code: "keychain.unavailable", message: nil, details: nil))
        return
      }
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: bundleId + ".vision",
        kSecAttrAccount as String: "openai",
        kSecUseDataProtectionKeychain as String: false,
        kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail
      ]
      switch call.method {
      case "read":
        guard call.arguments == nil else {
          result(FlutterError(code: "keychain.arguments", message: nil, details: nil))
          return
        }
        var readQuery = query
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &value)
        if status == errSecItemNotFound {
          result(nil)
        } else if status == errSecSuccess,
                  let data = value as? Data,
                  let secret = String(data: data, encoding: .utf8) {
          result(secret)
        } else {
          result(FlutterError(code: "keychain.unavailable", message: nil, details: nil))
        }
      case "write":
        guard let arguments = call.arguments as? [String: Any],
              Set(arguments.keys) == Set(["secret"]),
              let secret = arguments["secret"] as? String,
              !secret.isEmpty,
              secret.utf8.count <= 4096,
              secret.utf8.allSatisfy({ $0 > 32 && $0 < 127 }) else {
          result(FlutterError(code: "keychain.arguments", message: nil, details: nil))
          return
        }
        let data = Data(secret.utf8)
        var status = SecItemUpdate(
          query as CFDictionary,
          [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecItemNotFound {
          var item = query
          item[kSecValueData as String] = data
          item[kSecAttrLabel as String] = "Avelune Converter — OpenAI"
          status = SecItemAdd(item as CFDictionary, nil)
        }
        result(status == errSecSuccess ? nil : FlutterError(
          code: "keychain.unavailable", message: nil, details: nil
        ))
      case "delete":
        guard call.arguments == nil else {
          result(FlutterError(code: "keychain.arguments", message: nil, details: nil))
          return
        }
        let status = SecItemDelete(query as CFDictionary)
        result(status == errSecSuccess || status == errSecItemNotFound ? nil : FlutterError(
          code: "keychain.unavailable", message: nil, details: nil
        ))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
