import Flutter
import SwiftUI

@MainActor
final class AppComposition {
    let engineManager: FlutterEngineManager
    let gameDataSource: FlutterGameDataSource
    let platformChannel: HubPlatformChannel
    let gameRepository: GameRepositoryImpl
    let useCases: DefaultGameLibraryUseCases

    init() {
        engineManager = FlutterEngineManager()
        let engine = engineManager.ensureReady()
        platformChannel = HubPlatformChannel(engine: engine)
        gameDataSource = FlutterGameDataSource(engine: engine)
        gameRepository = GameRepositoryImpl(dataSource: gameDataSource)
        useCases = DefaultGameLibraryUseCases(repository: gameRepository)
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
