import Flutter
import SwiftUI

@MainActor
final class AppComposition {
    let engineManager: FlutterEngineManager
    let gameDataSource: FlutterGameDataSource
    let platformChannel: HubPlatformChannel
    let gameRepository: GameRepositoryImpl
    let useCases: DefaultGameLibraryUseCases
    let languagePreferences: AppLanguageSettings

    init() {
        engineManager = FlutterEngineManager()
        let engine = engineManager.ensureReady()
        platformChannel = HubPlatformChannel(engine: engine)
        gameDataSource = FlutterGameDataSource(engine: engine)
        gameRepository = GameRepositoryImpl(dataSource: gameDataSource)
        useCases = DefaultGameLibraryUseCases(repository: gameRepository)
        languagePreferences = AppLanguageSettings(
            read: gameDataSource.getLanguagePreferences,
            write: gameDataSource.setAppLanguage
        )
        gameDataSource.onRuntimeReady = { [weak languagePreferences] in
            Task { await languagePreferences?.runtimeReady() }
        }
        gameDataSource.onLanguagePreferencesChange = { [weak languagePreferences] preferences in
            languagePreferences?.receive(preferences)
        }
    }

    func makeGameListViewModel() -> GameListViewModel {
        GameListViewModel(
            loadLibraryUseCase: useCases,
            installGameUseCase: useCases
        )
    }

    func makeGamePlayerViewModel() -> GamePlayerViewModel {
        GamePlayerViewModel(
            playGameUseCase: useCases,
            engineManager: engineManager,
            dataSource: gameDataSource
        )
    }
}
