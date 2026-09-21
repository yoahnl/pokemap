import Flutter
import Foundation

/// Native side of the runtime channel.
///
/// The shell asks for a library and for a game to start; everything the player
/// sees once a game runs belongs to the Flutter runtime.
@MainActor
final class FlutterGameDataSource {
    private let channel: FlutterMethodChannel

    var onPlayerExit: (() -> Void)?

    init(engine: FlutterEngine) {
        channel = FlutterMethodChannel(
            name: "com.avelune.runtime/library",
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "playerDidExit" {
                self?.onPlayerExit?()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func listGames() async throws -> [Game] {
        try await games(from: invoke("listGames", arguments: nil))
    }

    func install(packagePath: String) async throws -> Game {
        let payload = try await invoke("installGame", arguments: ["packagePath": packagePath])
        guard let dictionary = payload as? [String: Any],
              let game = Game(payload: dictionary) else {
            throw RuntimeChannelError.invalidResponse
        }
        return game
    }

    func uninstall(gameId: String) async throws -> [Game] {
        try await games(from: invoke("uninstallGame", arguments: ["gameId": gameId]))
    }

    func play(gameId: String) async throws {
        _ = try await invoke("playGame", arguments: ["gameId": gameId])
    }

    func stop() async throws {
        _ = try await invoke("stopGame", arguments: nil)
    }

    private func games(from payload: Any?) throws -> [Game] {
        guard let rows = payload as? [[String: Any]] else {
            throw RuntimeChannelError.invalidResponse
        }
        return rows.compactMap(Game.init(payload:))
    }

    private func invoke(_ method: String, arguments: [String: Any]?) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod(method, arguments: arguments) { result in
                if let error = result as? FlutterError {
                    continuation.resume(
                        throwing: RuntimeChannelError.runtime(
                            error.message ?? error.code
                        )
                    )
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

enum RuntimeChannelError: LocalizedError {
    case invalidResponse
    case runtime(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Réponse inattendue de la runtime Avelune"
        case .runtime(let message):
            return message
        }
    }
}
