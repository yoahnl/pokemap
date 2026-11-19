import Flutter
import Foundation
import OSLog

/// Native side of the runtime channel.
///
/// The shell asks for a library and for a game to start; everything the player
/// sees once a game runs belongs to the Flutter runtime.
@MainActor
final class FlutterGameDataSource {
    private let channel: FlutterMethodChannel
    private let diagnostics: FlutterMethodChannel
    private let logger = Logger(subsystem: "com.yoahnl.avelune.player", category: "Runtime")

    var onPlayerExit: (() -> Void)?
    var onRuntimeReady: (() -> Void)?
    var onLanguagePreferencesChange: ((LanguagePreferences) -> Void)?
    private var onInstallProgress: ((InstallProgress) -> Void)?

    init(engine: FlutterEngine) {
        channel = FlutterMethodChannel(
            name: "com.avelune.runtime/library",
            binaryMessenger: engine.binaryMessenger
        )
        diagnostics = FlutterMethodChannel(
            name: "com.avelune.runtime/diagnostics",
            binaryMessenger: engine.binaryMessenger
        )
        diagnostics.setMethodCallHandler { call, result in
            if call.method == "processSample" {
                result(NativeProcessMetrics.read())
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "runtimeReady":
                result(nil)
                self?.onRuntimeReady?()
            case "languagePreferencesChanged":
                if let preferences = LanguagePreferences(payload: call.arguments) {
                    self?.onLanguagePreferencesChange?(preferences)
                }
                result(nil)
            case "playerDidExit":
                self?.onPlayerExit?()
                result(nil)
            case "installProgress":
                if let progress = InstallProgress(payload: call.arguments) {
                    self?.onInstallProgress?(progress)
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func getLanguagePreferences() async throws -> LanguagePreferences {
        let payload = try await invoke("getLanguagePreferences", arguments: nil)
        guard let preferences = LanguagePreferences(payload: payload) else {
            throw RuntimeChannelError.invalidResponse
        }
        return preferences
    }

    func setAppLanguage(_ language: AppLanguage) async throws -> LanguagePreferences {
        let payload = try await invoke("setAppLanguage", arguments: ["appLanguage": language.rawValue])
        guard let preferences = LanguagePreferences(payload: payload) else {
            throw RuntimeChannelError.invalidResponse
        }
        return preferences
    }

    func listGames() async throws -> [Game] {
        try await games(from: invoke("listGames", arguments: nil))
    }

    func install(packagePath: String, onProgress: @escaping (InstallProgress) -> Void) async throws -> Game {
        onInstallProgress = onProgress
        defer { onInstallProgress = nil }
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
        setDebugEnabled(false)
        _ = try await invoke("stopGame", arguments: nil)
    }

    func setDebugEnabled(_ enabled: Bool) {
        diagnostics.invokeMethod("setEnabled", arguments: ["enabled": enabled])
    }

    private func games(from payload: Any?) throws -> [Game] {
        guard let rows = payload as? [[String: Any]] else {
            throw RuntimeChannelError.invalidResponse
        }
        return rows.compactMap(Game.init(payload:))
    }

    private func invoke(_ method: String, arguments: [String: Any]?) async throws -> Any? {
        let logger = logger
        return try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod(method, arguments: arguments) { result in
                if let error = result as? FlutterError {
                    logger.error("\(method, privacy: .public) failed: \(error.code, privacy: .public) \(String(describing: error.details), privacy: .private)")
                    let details = error.details as? [String: Any]
                    continuation.resume(
                        throwing: RuntimeChannelError.runtime(
                            code: error.code,
                            message: error.message ?? error.code,
                            gameVersion: details?["gameVersion"] as? String
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
    case runtime(code: String, message: String, gameVersion: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the Avelune runtime."
        case .runtime(_, let message, _):
            return message
        }
    }

    var userFacingMessage: LocalizedStringResource? {
        switch self {
        case .invalidResponse:
            return "Réponse inattendue du moteur Avelune."
        case let .runtime(code, _, gameVersion):
            switch code {
            case "gameAlreadyPlaying":
                return "Une partie est déjà en cours."
            case "gameNotInstalled", "installation.notInstalled":
                return "Ce jeu ou cette version n’est plus installé sur cet appareil."
            case "installation.releaseConflict":
                if let gameVersion {
                    return "Une version \(gameVersion) au contenu différent est déjà installée. Téléchargez une version plus récente."
                }
                return "Une version du même numéro au contenu différent est déjà installée. Téléchargez une version plus récente."
            case "installation.cancelled":
                return "L’installation a été annulée."
            case "installation.incompatible":
                return "Ce jeu nécessite une autre version du Player."
            case "installation.insufficientDisk":
                return "Libérez de l’espace sur votre appareil pour installer ce jeu."
            case "installation.integrityFailed", "installation.sourceChanged":
                return "Le fichier du jeu est incomplet ou a été modifié."
            case "installation.notAnUpdate":
                return "Choisissez un fichier plus récent que la version installée."
            case "installation.alreadyInstalled":
                return "Cette version du jeu est déjà installée."
            case "installation.extractionFailed":
                return "Impossible de décompresser le jeu. Réessayez l’installation."
            case "installation.smokeFailed":
                return "Le jeu a échoué au démarrage pendant la vérification. Réessayez l’installation."
            case "installation.savePreparationFailed":
                return "Impossible de préparer les sauvegardes pour cette version."
            case "installation.unsafePath":
                return "Avelune ne peut pas utiliser son dossier de jeux sur cet appareil."
            case "installation.storageFailure":
                return "L’enregistrement du jeu a échoué. Réinstallez le même fichier pour réparer le jeu."
            case "installation.operationInProgress":
                return "Une opération est déjà en cours pour ce jeu. Attendez la fin, puis réessayez."
            case "installation.currentPointerCorrupt", "installation.receiptMissing", "installation.installationCorrupt":
                return "L’installation de ce jeu est endommagée. Réinstallez-le depuis son fichier."
            case "installation.repairIdentityMismatch":
                return "Utilisez le fichier d’origine de cette version pour réparer le jeu."
            case "installation.rollbackConfirmationRequired":
                return "Confirmez le retour à l’ancienne version avant de continuer."
            case "installation.rollbackSnapshotUnavailable":
                return "Les sauvegardes de cette ancienne version ne sont plus disponibles."
            case "installation.uninstallFallbackRequired":
                return "Choisissez la version à garder, puis désinstallez la version actuelle."
            default:
                return nil
            }
        }
    }
}
