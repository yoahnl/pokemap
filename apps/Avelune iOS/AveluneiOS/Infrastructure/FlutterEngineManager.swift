import Flutter
import Foundation

@MainActor
final class FlutterEngineManager {
    private(set) var engine: FlutterEngine?

    var isReady: Bool { engine != nil }

    func warmUp() {
        guard engine == nil else { return }
        let engine = FlutterEngine(name: "AveluneRuntime", project: nil)
        engine.run(withEntrypoint: nil, libraryURI: nil)
        self.engine = engine
    }

    func shutdown() {
        engine?.destroyContext()
        engine = nil
    }

    func ensureReady() -> FlutterEngine {
        if let engine = engine { return engine }
        warmUp()
        return engine!
    }
}
