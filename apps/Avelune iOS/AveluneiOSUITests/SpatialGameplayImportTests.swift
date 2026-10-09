import XCTest

final class SpatialGameplayImportTests: XCTestCase {
    func testDebugHudFollowsNativeSettingsAndPreservesGameplay() throws {
        let configuration = try durabilityConfiguration()
        let app = launchDurabilityApplication(configuration)
        try setDebugPreference(true, in: app)
        try resumeDurabilityGame(configuration.gameTitle, in: app)
        let heading = app.staticTexts["DEBUG · MOTEUR"].firstMatch
        try require(heading.waitForExistence(timeout: 15), "Le toggle natif doit afficher le vrai HUD dans le moteur.", app)
        let memory = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "RAM ")).firstMatch
        let measured = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            memory.exists && !memory.label.contains("N/D")
        }, object: nil)
        try require(XCTWaiter.wait(for: [measured], timeout: 10) == .completed, "La mémoire affichée doit provenir du processus natif.", app)
        attachScreenshot(app, name: "debug-hud-native-portrait")
        try setDurabilityOrientation("landscapeLeft", in: app)
        attachScreenshot(app, name: "debug-hud-native-landscape")
        try performDurabilityAction(["kind": "move", "direction": "right", "holdSeconds": 0.2], in: app)
        let menu = app.buttons["Menu"].firstMatch
        menu.tap()
        try require(app.buttons["pause.save"].firstMatch.waitForExistence(timeout: 10), "Le HUD doit laisser le vrai menu de jeu utilisable.", app)
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
        app.launch()
        try setDebugPreference(false, in: app)
        try resumeDurabilityGame(configuration.gameTitle, in: app)
        try require(!heading.waitForExistence(timeout: 3), "Désactiver le toggle doit retirer le HUD de la prochaine partie.", app)
        attachScreenshot(app, name: "debug-hud-native-disabled")
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
    }

    private func setDebugPreference(_ enabled: Bool, in app: XCUIApplication) throws {
        try setDurabilityOrientation("portrait", in: app)
        let settings = button(["Réglages", "Settings"], in: app)
        try require(settings.waitForExistence(timeout: 10), "Les réglages natifs doivent être accessibles.", app)
        settings.tap()
        let toggle = app.switches.firstMatch
        try require(toggle.waitForExistence(timeout: 10), "Le toggle natif Infos de debug doit être présent.", app)
        if (toggle.value as? String == "1") != enabled { toggle.tap() }
        let games = button(["Jeux", "Games"], in: app)
        try require(games.waitForExistence(timeout: 10), "La bibliothèque native doit rester accessible.", app)
        games.tap()
    }

    private var application: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
    }

    override func tearDownWithError() throws {
        if let app = application, app.state != .notRunning {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "spatial-ios-final-accessibility-tree"
            tree.lifetime = .keepAlways
            add(tree)
            attachScreenshot(app, name: "spatial-ios-final")
        }
    }

    func testImportAndSaveSpatialDurabilityCheckpoint() throws {
        let configuration = try durabilityConfiguration()
        let app = launchDurabilityApplication(configuration)
        let importButton = app.buttons["Importer un jeu"].firstMatch
        try require(importButton.waitForExistence(timeout: 45), "La bibliothèque native doit proposer son import.", app)
        let gameCount = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@ OR label == %@", "^[0-9]+ aventures?$", "Vos aventures commencent ici.")).firstMatch
        try require(gameCount.waitForExistence(timeout: 45), "L’inventaire réel doit être chargé avant de vérifier que la cartouche QA est absente.", app)
        let cover = gameCover(configuration.gameTitle, in: app)
        let existingTitle = app.staticTexts[configuration.gameTitle].firstMatch
        try require(!cover.exists && !existingTitle.exists, "La cartouche de durabilité doit être absente de l’application isolée avant son import.", app)
        attachScreenshot(app, name: "durability-ios-library-before-import")
        importButton.tap()
        try choosePackage(configuration.packageName, documentsFolderName: configuration.documentsFolderName, in: app)
        attachScreenshot(app, name: "durability-ios-library-imported")
        try openGameTitle(configuration.gameTitle, in: app)
        try startAndSaveDurabilityNewGame(configuration, in: app)
    }

    func testStartAndSaveImportedSpatialDurabilityCheckpoint() throws {
        let configuration = try durabilityConfiguration()
        let app = launchDurabilityApplication(configuration)
        try openGameTitle(configuration.gameTitle, in: app)
        try startAndSaveDurabilityNewGame(configuration, in: app)
    }

    private func startAndSaveDurabilityNewGame(_ configuration: SpatialDurabilityConfiguration, in app: XCUIApplication) throws {
        let newGame = button(["Nouveau jeu", "New game"], in: app)
        try require(newGame.waitForExistence(timeout: 30) && newGame.isHittable, "Le jeu importé doit proposer une nouvelle partie.", app)
        newGame.tap()
        let replacement = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Cette sauvegarde existe déjà")).firstMatch
        if replacement.waitForExistence(timeout: 1) {
            let environment = ProcessInfo.processInfo.environment
            try require((environment["ENV_AVELUNE_UI_REPLACE_QA_SAVE"] ?? environment["AVELUNE_UI_REPLACE_QA_SAVE"]) == "1", "Remplacer une sauvegarde QA exige une configuration explicite du parcours.", app)
            button(["Oui", "Yes"], in: app).tap()
        }
        try finishDurabilityIntroduction(configuration.expectedDialogue, in: app)
        attachScreenshot(app, name: "durability-ios-new-game-world")
        try captureDurabilityOrientations("new-game", in: app)
        try saveDurabilityCheckpoint("before-process-termination", in: app)
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
    }

    func testPlayAndSaveSpatialDurabilityCheckpoint() throws {
        let configuration = try durabilityConfiguration()
        let actions = try durabilityActions()
        let app = launchDurabilityApplication(configuration)
        try resumeDurabilityGame(configuration.gameTitle, in: app)
        for (index, action) in actions.enumerated() {
            try performDurabilityAction(action, in: app)
            attachScreenshot(app, name: "durability-ios-real-action-\(index + 1)")
        }
        try require(app.buttons["Menu"].firstMatch.waitForExistence(timeout: 30), "Le parcours réel doit terminer dans l’exploration avant de sauvegarder.", app)
        try saveDurabilityCheckpoint("after-real-world-actions", in: app)
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
    }

    func testObserveSpatialGameplayActions() throws {
        let configuration = try durabilityConfiguration()
        let actions = try durabilityActions()
        let app = launchDurabilityApplication(configuration)
        try resumeDurabilityGame(configuration.gameTitle, in: app)
        for (index, action) in actions.enumerated() {
            try performDurabilityAction(action, in: app)
            attachScreenshot(app, name: "durability-ios-observed-action-\(index + 1)")
        }
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "durability-ios-observed-gameplay-accessibility-tree"
        tree.lifetime = .keepAlways
        add(tree)
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
    }

    private func durabilityActions() throws -> [[String: Any]] {
        let environment = ProcessInfo.processInfo.environment
        guard let actionsText = environment["ENV_AVELUNE_UI_DURABILITY_ACTIONS"] ?? environment["AVELUNE_UI_DURABILITY_ACTIONS"],
              let actionsData = actionsText.data(using: .utf8),
              let actions = try JSONSerialization.jsonObject(with: actionsData) as? [[String: Any]],
              !actions.isEmpty, actions.count <= 32 else {
            throw XCTSkip("Le parcours jouable de durabilité exige de 1 à 32 gestes, dialogues ou actions UI explicites.")
        }
        return actions
    }

    func testResumeSpatialDurabilityCheckpointAfterProcessTermination() throws {
        let configuration = try durabilityConfiguration()
        let app = launchDurabilityApplication(configuration)
        try resumeDurabilityGame(configuration.gameTitle, in: app)
        attachScreenshot(app, name: "durability-ios-restored-world")
        try captureDurabilityOrientations("restored-world", in: app)
        try saveDurabilityCheckpoint("after-fresh-process-continue", in: app)
        try terminateDurabilityApplication(app, bundleId: configuration.bundleId)
    }

    private func resumeDurabilityGame(_ title: String, in app: XCUIApplication) throws {
        try openGameTitle(title, in: app)
        let resume = app.buttons.matching(NSPredicate(format: "label IN %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@", ["Continuer", "Continue"], "Continuer\n", "Continue\n")).firstMatch
        try require(resume.waitForExistence(timeout: 30) && resume.isHittable, "Une nouvelle instance du processus doit découvrir la sauvegarde persistée et proposer Continuer.", app)
        attachScreenshot(app, name: "durability-ios-fresh-process-continue-title")
        resume.tap()
        let menu = app.buttons["Menu"].firstMatch
        try require(menu.waitForExistence(timeout: 45) && menu.isHittable, "Continuer doit restaurer une nouvelle session jouable.", app)
    }

    private func performDurabilityAction(_ action: [String: Any], in app: XCUIApplication) throws {
        switch action["kind"] as? String {
        case "move":
            guard let direction = action["direction"] as? String,
                  let hold = action["holdSeconds"] as? NSNumber,
                  hold.doubleValue >= 0, hold.doubleValue <= 3 else {
                throw SpatialGateFailure.unexpectedSurface("Un geste doit nommer sa direction et une durée entre 0 et 3 secondes.")
            }
            let distance = (action["distancePoints"] as? NSNumber)?.doubleValue ?? 30
            guard distance >= 12, distance <= 96 else {
                throw SpatialGateFailure.unexpectedSurface("L’amplitude du geste doit être comprise entre 12 et 96 points.")
            }
            let end: CGVector
            switch direction {
            case "left": end = CGVector(dx: -distance, dy: 0)
            case "right": end = CGVector(dx: distance, dy: 0)
            case "up": end = CGVector(dx: 0, dy: -distance)
            case "down": end = CGVector(dx: 0, dy: distance)
            default: throw SpatialGateFailure.unexpectedSurface("Direction tactile inconnue : \(direction).")
            }
            try require(app.buttons["Menu"].firstMatch.exists, "Un déplacement réel exige une session d’exploration active.", app)
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.55))
            start.press(forDuration: 0.02, thenDragTo: start.withOffset(end), withVelocity: .fast, thenHoldForDuration: hold.doubleValue)
            Thread.sleep(forTimeInterval: 0.6)
        case "tap":
            guard let labels = action["labels"] as? [String], !labels.isEmpty, labels.count <= 8 else {
                throw SpatialGateFailure.unexpectedSurface("Une action réelle exige les libellés visibles de son bouton.")
            }
            let target = app.buttons.matching(NSPredicate(format: "label IN %@ OR identifier IN %@", labels, labels)).firstMatch
            try require(target.waitForExistence(timeout: 15) && target.isHittable, "Le bouton réel \(labels) doit être disponible dans la session.", app)
            target.tap()
        case "assertVisible":
            guard let text = action["contains"] as? String, !text.isEmpty, text.count <= 200 else {
                throw SpatialGateFailure.unexpectedSurface("Une preuve visible doit préciser son texte d’interface.")
            }
            let target = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                target.exists && target.isHittable
            }, object: nil)
            try require(XCTWaiter.wait(for: [visible], timeout: 30) == .completed, "L’interface réelle doit afficher : \(text).", app)
        case "assertAbsent":
            guard let labels = action["labels"] as? [String], !labels.isEmpty, labels.count <= 16,
                  labels.allSatisfy({ !$0.isEmpty && $0.count <= 200 }) else {
                throw SpatialGateFailure.unexpectedSurface("Une preuve d’absence doit préciser les libellés d’interface concernés.")
            }
            try requireDurabilityLabelsAbsent(labels, in: app)
        case "finishedBattle":
            guard let commands = action["commandLabels"] as? [String], !commands.isEmpty, commands.count <= 8,
                  let hud = action["hudContains"] as? [String], !hud.isEmpty, hud.count <= 8,
                  (commands + hud).allSatisfy({ !$0.isEmpty && $0.count <= 200 }) else {
                throw SpatialGateFailure.unexpectedSurface("Le retour de combat doit nommer les commandes et les HUD réellement observés.")
            }
            try requireDurabilityLabelsAbsent(commands, in: app)
            let absentHud = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                hud.allSatisfy { text in
                    !app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.exists
                }
            }, object: nil)
            try require(XCTWaiter.wait(for: [absentHud], timeout: 30) == .completed, "Les HUD de combat doivent quitter la scène avant le retour à l’exploration.", app)
            let menu = app.buttons["Menu"].firstMatch
            try require(menu.waitForExistence(timeout: 30) && menu.isHittable, "L’exploration doit rendre son menu tactile après le combat.", app)
            menu.tap()
            let save = app.buttons["pause.save"].firstMatch
            try require(save.waitForExistence(timeout: 10) && save.isHittable, "Le retour de combat doit permettre d’ouvrir le vrai menu de jeu.", app)
            attachScreenshot(app, name: "durability-ios-playable-menu-after-battle")
            let resume = app.buttons["pause-frame-return"].firstMatch
            try require(resume.waitForExistence(timeout: 10) && resume.isHittable, "Le menu après combat doit rendre le contrôle au joueur.", app)
            resume.tap()
            try require(menu.waitForExistence(timeout: 10) && menu.isHittable, "Le monde doit être jouable après fermeture du menu suivant le combat.", app)
        case "dialogue":
            guard let text = action["contains"] as? String, !text.isEmpty else {
                throw SpatialGateFailure.unexpectedSurface("Le dialogue attendu doit préciser son texte visible.")
            }
            let dialogue = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
            try require(dialogue.waitForExistence(timeout: 20), "La narration ordinaire doit afficher le dialogue attendu : \(text).", app)
            attachScreenshot(app, name: "durability-ios-expected-world-dialogue")
            let menu = app.buttons["Menu"].firstMatch
            for _ in 0..<12 {
                if menu.exists && menu.isHittable { return }
                let next = app.descendants(matching: .any).matching(
                    NSPredicate(format: "label IN %@ OR identifier == %@", ["Afficher", "Show", "Suite", "Next", "Fermer", "Close", "Continuer", "Continue"], "dialogue-tap-zone")
                ).firstMatch
                let available = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    (menu.exists && menu.isHittable) || (next.exists && next.isHittable)
                }, object: nil)
                try require(XCTWaiter.wait(for: [available], timeout: 15) == .completed, "Le dialogue ou sa cinématique doit rendre un contrôle tactile ordinaire.", app)
                if menu.exists && menu.isHittable { return }
                next.tap()
                _ = menu.waitForExistence(timeout: 2)
            }
            try require(menu.waitForExistence(timeout: 20) && menu.isHittable, "Le dialogue doit rendre le contrôle au joueur.", app)
        case "wait":
            guard let seconds = action["seconds"] as? NSNumber, seconds.doubleValue >= 0, seconds.doubleValue <= 5 else {
                throw SpatialGateFailure.unexpectedSurface("Une attente UI doit durer entre 0 et 5 secondes.")
            }
            Thread.sleep(forTimeInterval: seconds.doubleValue)
        case "background":
            guard let seconds = action["seconds"] as? NSNumber, seconds.doubleValue >= 0, seconds.doubleValue <= 5 else {
                throw SpatialGateFailure.unexpectedSurface("Le passage en arrière-plan doit durer entre 0 et 5 secondes.")
            }
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: seconds.doubleValue)
            app.activate()
            try require(app.wait(for: .runningForeground, timeout: 15), "L’application doit revenir au premier plan.", app)
        case "orientation":
            guard let orientation = action["value"] as? String else {
                throw SpatialGateFailure.unexpectedSurface("Une orientation doit préciser portrait ou paysage.")
            }
            try setDurabilityOrientation(orientation, in: app)
        default:
            throw SpatialGateFailure.unexpectedSurface("Action de durabilité inconnue.")
        }
    }

    private func requireDurabilityLabelsAbsent(_ labels: [String], in app: XCUIApplication) throws {
        let absent = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", labels)).firstMatch.exists
        }, object: nil)
        try require(XCTWaiter.wait(for: [absent], timeout: 30) == .completed, "Les anciens contrôles doivent être absents : \(labels).", app)
    }

    private func durabilityConfiguration() throws -> SpatialDurabilityConfiguration {
        let environment = ProcessInfo.processInfo.environment
        func value(_ name: String) -> String? {
            environment["ENV_\(name)"] ?? environment[name]
        }
        guard let bundleId = value("AVELUNE_UI_BUNDLE_ID"),
              bundleId.hasPrefix("com.yoahnl.avelune.player.durable3dqa"),
              bundleId.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || $0 == "." || $0 == "-" }) else {
            throw XCTSkip("Le parcours de durabilité exige un bundle natif durable3dqa isolé de l’application utilisateur.")
        }
        guard let packageName = value("AVELUNE_UI_GAME_PACKAGE_NAME"),
              !packageName.isEmpty, !packageName.contains("/"), !packageName.contains("\\"),
              let gameTitle = value("AVELUNE_UI_GAME_TITLE"), !gameTitle.isEmpty,
              let expectedDialogue = value("AVELUNE_UI_DURABILITY_EXPECTED_DIALOGUE"), !expectedDialogue.isEmpty else {
            throw XCTSkip("Le parcours de durabilité exige le nom Files, le titre et le dialogue attestant les actions narratives de la cartouche QA.")
        }
        let documentsFolderName = value("AVELUNE_UI_DOCUMENTS_FOLDER") ?? "Avelune"
        guard !documentsFolderName.isEmpty, !documentsFolderName.contains("/"), !documentsFolderName.contains("\\") else {
            throw XCTSkip("Le dossier Files QA doit porter un nom d’application explicite.")
        }
        return SpatialDurabilityConfiguration(bundleId: bundleId, packageName: packageName, gameTitle: gameTitle, expectedDialogue: expectedDialogue, documentsFolderName: documentsFolderName)
    }

    private func launchDurabilityApplication(_ configuration: SpatialDurabilityConfiguration) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: configuration.bundleId)
        application = app
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        return app
    }

    private func captureDurabilityOrientations(_ name: String, in app: XCUIApplication) throws {
        try setDurabilityOrientation("portrait", in: app)
        attachScreenshot(app, name: "durability-ios-\(name)-portrait")
        try setDurabilityOrientation("landscapeLeft", in: app)
        attachScreenshot(app, name: "durability-ios-\(name)-landscape")
        try setDurabilityOrientation("portrait", in: app)
    }

    private func setDurabilityOrientation(_ orientation: String, in app: XCUIApplication) throws {
        let portrait: Bool
        switch orientation {
        case "portrait":
            XCUIDevice.shared.orientation = .portrait
            portrait = true
        case "landscapeLeft":
            XCUIDevice.shared.orientation = .landscapeLeft
            portrait = false
        default:
            throw SpatialGateFailure.unexpectedSurface("Orientation QA inconnue : \(orientation).")
        }
        let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let bounds = app.frame
            return bounds.width > 0 && bounds.height > 0 && (portrait ? bounds.height > bounds.width : bounds.width > bounds.height)
        }, object: nil)
        try require(XCTWaiter.wait(for: [rotated], timeout: 15) == .completed, "Le runtime QA doit présenter la vue jouable dans l’orientation demandée.", app)
        Thread.sleep(forTimeInterval: 1)
    }

    private func gameCover(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, "voir la fiche")).firstMatch
    }

    private func openGameTitle(_ title: String, in app: XCUIApplication) throws {
        let library = app.scrollViews["library-scroll"].firstMatch
        try require(library.waitForExistence(timeout: 45) && library.isHittable, "La bibliothèque doit permettre de retrouver la cartouche importée après le lancement du processus.", app)
        var hittableCover: XCUIElement?
        for _ in 0..<4 {
            hittableCover = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, "voir la fiche")).allElementsBoundByIndex.first(where: { $0.isHittable })
            if hittableCover != nil { break }
            library.swipeUp()
        }
        try require(hittableCover != nil, "La fiche de la cartouche QA doit être accessible.", app)
        try XCTUnwrap(hittableCover).tap()
        let play = button(["Jouer", "Reprendre"], in: app)
        try require(play.waitForExistence(timeout: 10) && play.isHittable, "La fiche doit lancer le vrai runtime embarqué.", app)
        play.tap()
        let titlePrompt = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ OR identifier == %@", "Appuyer sur Start", "player-title-prompt-hit-area")
        ).firstMatch
        try require(titlePrompt.waitForExistence(timeout: 45) && titlePrompt.isHittable, "Le jeu doit atteindre son écran titre réel.", app)
        titlePrompt.tap()
    }

    private func finishDurabilityIntroduction(_ expectedDialogue: String, in app: XCUIApplication) throws {
        let menu = app.buttons["Menu"].firstMatch
        let checkpoint = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", expectedDialogue)).firstMatch
        var checkpointSeen = false
        for _ in 0..<12 {
            checkpointSeen = checkpointSeen || checkpoint.waitForExistence(timeout: 1)
            if menu.exists && menu.isHittable { break }
            let next = app.descendants(matching: .any).matching(
                NSPredicate(format: "label IN %@ OR identifier == %@", ["Afficher", "Show", "Suite", "Next", "Fermer", "Close", "Continuer", "Continue"], "dialogue-tap-zone")
            ).firstMatch
            let available = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (menu.exists && menu.isHittable) || (next.exists && next.isHittable)
            }, object: nil)
            try require(XCTWaiter.wait(for: [available], timeout: 15) == .completed, "L’introduction doit avancer par ses contrôles de dialogue réels.", app)
            if menu.exists && menu.isHittable { break }
            if checkpoint.exists {
                checkpointSeen = true
                attachScreenshot(app, name: "durability-ios-narrative-checkpoint")
            }
            next.tap()
            _ = menu.waitForExistence(timeout: 2)
        }
        try require(checkpointSeen, "La vraie introduction de la cartouche QA doit afficher le dialogue attendu.", app)
        try require(menu.waitForExistence(timeout: 30) && menu.isHittable, "La narration doit rendre le contrôle à l’exploration avant la sauvegarde.", app)
    }

    private func saveDurabilityCheckpoint(_ name: String, in app: XCUIApplication) throws {
        app.buttons["Menu"].firstMatch.tap()
        let save = app.buttons["pause.save"].firstMatch
        try require(save.waitForExistence(timeout: 10) && save.isHittable, "Le vrai menu doit proposer la sauvegarde.", app)
        save.tap()
        let confirm = button(["Sauvegarder", "Save"], in: app)
        try require(confirm.waitForExistence(timeout: 5) && confirm.isHittable, "La sauvegarde doit demander sa confirmation réelle.", app)
        confirm.tap()
        let success = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Partie sauvegardée")).firstMatch
        try require(success.waitForExistence(timeout: 20), "La vraie écriture persistante doit afficher son reçu avant l’arrêt complet du processus.", app)
        attachScreenshot(app, name: "durability-ios-save-\(name)")
    }

    private func terminateDurabilityApplication(_ app: XCUIApplication, bundleId: String) throws {
        app.terminate()
        let terminated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.state == .notRunning }, object: nil)
        try require(XCTWaiter.wait(for: [terminated], timeout: 10) == .completed, "Le processus natif doit être réellement arrêté avant la phase suivante.", app)
        let receipt = XCTAttachment(string: "bundleId=\(bundleId)\nstate=notRunning\nphase=process-terminated")
        receipt.name = "durability-ios-process-termination"
        receipt.lifetime = .keepAlways
        add(receipt)
    }

    func testImportPackageAndPlaySpatialNewGameWithTouch() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let packagePath = environment["ENV_AVELUNE_UI_GAME_PACKAGE_PATH"] else {
            throw XCTSkip("TEST_RUNNER_ENV_AVELUNE_UI_GAME_PACKAGE_PATH absent du lancement Xcode ; clés Valbois présentes : \(environment.keys.filter { $0.contains("AVELUNE_UI") }.sorted()).")
        }
        guard packagePath.hasPrefix("/"),
              URL(fileURLWithPath: packagePath).pathExtension == "avelunegame" else {
            throw XCTSkip("AVELUNE_UI_GAME_PACKAGE_PATH doit être un chemin absolu vers un paquet .avelunegame : \(packagePath).")
        }
        guard FileManager.default.fileExists(atPath: packagePath) else {
            throw XCTSkip("Le runner ne peut pas lire le vrai paquet du fournisseur Documents : \(packagePath).")
        }
        let packageName = URL(fileURLWithPath: packagePath).deletingPathExtension().lastPathComponent
        guard let simulatorDataPath = environment["ENV_AVELUNE_UI_SIMULATOR_DATA_ROOT"], simulatorDataPath.hasPrefix("/") else {
            throw XCTSkip("TEST_RUNNER_ENV_AVELUNE_UI_SIMULATOR_DATA_ROOT absent du lancement Xcode pour la lecture seule des sauvegardes.")
        }
        let simulatorDataRoot = URL(fileURLWithPath: simulatorDataPath, isDirectory: true)
        let gameTitle = environment["ENV_AVELUNE_UI_GAME_TITLE"] ?? "Valbois — Voyage en 3D"
        let app = XCUIApplication()
        application = app
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let importButton = app.buttons["Importer un jeu"].firstMatch
        try require(importButton.waitForExistence(timeout: 30), "Le bouton d’import de la bibliothèque doit apparaître.", app)
        let gameCount = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ aventures?$")).firstMatch
        try require(gameCount.waitForExistence(timeout: 45), "La bibliothèque doit terminer son chargement avant le parcours d’import.", app)
        let cover = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", gameTitle, "voir la fiche")
        ).firstMatch
        try removeExistingQACartridge(gameTitle, cover: cover, in: app)
        try require(!cover.exists, "Le jeu QA doit être absent avant le test afin de prouver un nouvel import.", app)
        try require(gameCount.waitForExistence(timeout: 10), "La bibliothèque doit afficher son inventaire avant l’import.", app)
        let previousGameCount = gameCount.label
        attachScreenshot(app, name: "spatial-ios-library-before-import")
        importButton.tap()
        try choosePackage(packageName, in: app)

        let importResult = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                cover.exists || app.alerts["Erreur"].exists ||
                    (gameCount.exists && gameCount.label != previousGameCount)
            },
            object: nil
        )
        _ = XCTWaiter.wait(for: [importResult], timeout: 90)
        let library = app.scrollViews["library-scroll"].firstMatch
        for _ in 0..<4 {
            if cover.exists && cover.isHittable { break }
            if app.alerts["Erreur"].exists { break }
            library.swipeUp()
        }
        try require(cover.exists, "Le vrai import doit ajouter la fiche du jeu \(gameTitle).", app)
        attachScreenshot(app, name: "spatial-ios-library-imported")
        if !cover.isHittable {
            app.swipeUp()
        }
        try require(cover.isHittable, "La fiche du jeu importé doit être accessible.", app)
        cover.tap()

        let play = button(["Jouer", "Reprendre"], in: app)
        try require(play.waitForExistence(timeout: 10), "La fiche doit proposer le lancement du jeu.", app)
        play.tap()
        let titlePrompt = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ OR identifier == %@", "Appuyer sur Start", "player-title-prompt-hit-area")
        ).firstMatch
        try require(titlePrompt.waitForExistence(timeout: 45) && titlePrompt.isHittable, "Le vrai titre Flutter doit afficher son contrôle de démarrage.", app)
        attachScreenshot(app, name: "spatial-ios-title-prompt")
        titlePrompt.tap()
        let newGame = button(["Nouveau jeu", "New game"], in: app)
        try require(newGame.waitForExistence(timeout: 45), "Le titre Flutter doit proposer une nouvelle partie.", app)
        attachScreenshot(app, name: "spatial-ios-flutter-title")
        newGame.tap()
        let replaceSave = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "Cette sauvegarde existe déjà")
        ).firstMatch
        if replaceSave.waitForExistence(timeout: 5) {
            let confirmReplacement = button(["Oui", "Yes"], in: app)
            try require(confirmReplacement.exists && confirmReplacement.isHittable, "La nouvelle partie doit confirmer le remplacement de la sauvegarde QA dans la vraie UI.", app)
            confirmReplacement.tap()
        }

        let introduction = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "Bienvenue à Valbois")
        ).firstMatch
        try require(introduction.waitForExistence(timeout: 20), "La vraie scène d’introduction doit être visible.", app)
        attachScreenshot(app, name: "spatial-ios-introduction")
        let menu = app.buttons["Menu"].firstMatch
        for _ in 0..<6 {
            if menu.exists && menu.isHittable { break }
            let next = app.descendants(matching: .any).matching(
                NSPredicate(format: "label IN %@ OR identifier == %@", ["Afficher", "Show", "Suite", "Next", "Fermer", "Close", "Continuer", "Continue"], "dialogue-tap-zone")
            ).firstMatch
            try require(next.waitForExistence(timeout: 5), "L’introduction doit proposer son contrôle de continuation.", app)
            next.tap()
            _ = menu.waitForExistence(timeout: 2)
        }
        try require(menu.waitForExistence(timeout: 30) && menu.isHittable, "La partie doit atteindre la surface jouable avec son menu tactile.", app)
        let initialPose = try saveSpatialPose("before-touch", in: app, simulatorDataRoot: simulatorDataRoot)
        attachScreenshot(app, name: "spatial-ios-before-touch")

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.55))
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.55))
        start.press(forDuration: 0.12, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.60)
        attachScreenshot(app, name: "spatial-ios-after-touch-right")
        let up = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.45))
        start.press(forDuration: 0.12, thenDragTo: up, withVelocity: .slow, thenHoldForDuration: 0.60)
        attachScreenshot(app, name: "spatial-ios-after-touch-up")
        Thread.sleep(forTimeInterval: 1.1)
        attachScreenshot(app, name: "spatial-ios-stopped-after-release")
        let movedPose = try saveSpatialPose("after-touch", in: app, simulatorDataRoot: simulatorDataRoot)
        try require(movedPose.mapId == initialPose.mapId && movedPose.x > initialPose.x && movedPose.z < initialPose.z, "Les vraies sauvegardes doivent prouver le déplacement tactile à droite puis vers le haut.", app)
        try require(menu.exists && menu.isHittable, "Le joueur doit rester actif après les gestes tactiles.", app)
        menu.tap()

        let party = app.buttons["pause.party"].firstMatch
        try require(party.waitForExistence(timeout: 10), "Le vrai menu doit proposer l’équipe.", app)
        party.tap()
        let starter = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Bulbizarre", "Bulbasaur")
        ).firstMatch
        try require(starter.waitForExistence(timeout: 10), "L’équipe réelle doit afficher le Bulbizarre initial.", app)
        attachScreenshot(app, name: "spatial-ios-party")

        let back = button(["Retour", "Back"], in: app)
        try require(back.waitForExistence(timeout: 5), "L’équipe doit permettre de revenir au menu.", app)
        back.tap()
        let resume = button(["Reprendre", "Resume"], in: app)
        try require(resume.waitForExistence(timeout: 5), "Le menu doit permettre de reprendre la partie.", app)
        resume.tap()
        try require(menu.waitForExistence(timeout: 10) && menu.isHittable, "La vue jouable doit reprendre après le menu.", app)
        attachScreenshot(app, name: "spatial-ios-resumed")
    }

    private func choosePackage(_ name: String, documentsFolderName: String = "Avelune", in app: XCUIApplication) throws {
        let pickerFile = app.cells.matching(
            NSPredicate(format: "label BEGINSWITH[c] %@ OR identifier BEGINSWITH[c] %@", name, name)
        ).firstMatch
        if !pickerFile.waitForExistence(timeout: 4) {
            let browse = button(["Parcourir", "Explorer", "Browse"], in: app)
            if browse.waitForExistence(timeout: 20) && browse.isHittable {
                browse.tap()
            }
            let local = app.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@ OR label == %@", "Sur mon iPhone", "On My iPhone")
            ).firstMatch
            if local.waitForExistence(timeout: 8) && local.isHittable {
                local.tap()
            }
            let documents = app.cells.matching(NSPredicate(format: "label BEGINSWITH[c] %@ OR identifier BEGINSWITH[c] %@", documentsFolderName, documentsFolderName)).firstMatch
            if !pickerFile.exists && documents.waitForExistence(timeout: 5) && documents.isHittable {
                documents.tap()
            }
            if !pickerFile.waitForExistence(timeout: 3) {
                let search = app.searchFields.firstMatch
                try require(search.waitForExistence(timeout: 5), "Le sélecteur Documents doit exposer le fichier ou sa recherche.", app)
                search.tap()
                search.typeText(name)
                let keyboardIntroduction = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Speed up your typing")).firstMatch
                if keyboardIntroduction.exists {
                    button(["Continue", "Continuer"], in: app).tap()
                }
                search.typeText("\n")
            }
        }
        let pickerTree = XCTAttachment(string: app.debugDescription)
        pickerTree.name = "spatial-ios-document-picker-accessibility-tree"
        pickerTree.lifetime = .keepAlways
        add(pickerTree)
        attachScreenshot(app, name: "spatial-ios-document-picker")
        try require(pickerFile.waitForExistence(timeout: 15) && pickerFile.isHittable, "Le paquet \(name) doit être sélectionnable dans le vrai fournisseur Files.", app)
        pickerFile.tap()
        let open = button(["Ouvrir", "Open"], in: app)
        if open.waitForExistence(timeout: 2) && open.isHittable {
            open.tap()
        }
    }

    private func removeExistingQACartridge(_ title: String, cover: XCUIElement, in app: XCUIApplication) throws {
        let library = app.scrollViews["library-scroll"].firstMatch
        for _ in 0..<3 {
            if cover.exists && cover.isHittable { break }
            library.swipeUp()
        }
        if cover.exists {
            let options = app.buttons["Options pour \(title)"].firstMatch
            try require(options.exists && options.isHittable, "Seules les options de la cartouche QA peuvent être ouvertes pour le nettoyage.", app)
            options.tap()
            let remove = app.buttons["Supprimer le jeu"].firstMatch
            try require(remove.waitForExistence(timeout: 5), "Le nettoyage doit passer par la vraie commande de suppression du jeu.", app)
            remove.tap()
            let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !cover.exists }, object: nil)
            try require(XCTWaiter.wait(for: [removed], timeout: 20) == .completed, "La cartouche QA doit quitter la bibliothèque avant le nouvel import.", app)
            attachScreenshot(app, name: "spatial-ios-qa-cartridge-removed")
        }
        for _ in 0..<3 { library.swipeDown() }
    }

    private func saveSpatialPose(_ name: String, in app: XCUIApplication, simulatorDataRoot: URL) throws -> SpatialSavedPose {
        app.buttons["Menu"].firstMatch.tap()
        let save = app.buttons["pause.save"].firstMatch
        try require(save.waitForExistence(timeout: 10) && save.isHittable, "Le vrai menu doit proposer la sauvegarde.", app)
        save.tap()
        let confirm = button(["Sauvegarder", "Save"], in: app)
        try require(confirm.waitForExistence(timeout: 5) && confirm.isHittable, "La sauvegarde doit demander une confirmation réelle.", app)
        confirm.tap()
        let success = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Partie sauvegardée")).firstMatch
        try require(success.waitForExistence(timeout: 20), "La vraie sauvegarde doit être confirmée par son reçu.", app)
        attachScreenshot(app, name: "spatial-ios-save-\(name)")

        let containers = simulatorDataRoot.appendingPathComponent("Containers/Data/Application", isDirectory: true)
        let candidates = try FileManager.default.contentsOfDirectory(at: containers, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        let appContainers = candidates.filter { candidate in
            guard let values = try? candidate.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]), values.isDirectory == true, values.isSymbolicLink != true,
                  let metadata = try? Data(contentsOf: candidate.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")),
                  let dictionary = try? PropertyListSerialization.propertyList(from: metadata, options: [], format: nil) as? [String: Any] else { return false }
            return dictionary["MCMMetadataIdentifier"] as? String == "com.yoahnl.avelune.player"
        }
        try require(appContainers.count == 1, "Le store doit être lu dans l’unique conteneur réel de l’application iOS.", app)
        let saveFile = appContainers[0].appendingPathComponent("Library/Application Support/PokeMap/saves/games.yoahn.valbois/default/slot-1/save.json")
        let data = try Data(contentsOf: saveFile)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(envelope["gameId"] as? String, "games.yoahn.valbois")
        let state = try XCTUnwrap(envelope["state"] as? [String: Any])
        let spatial = try XCTUnwrap(state["playerSpatialPosition"] as? [String: Any])
        let grid = try XCTUnwrap(state["playerPosition"] as? [String: Any])
        let pose = SpatialSavedPose(
            mapId: try XCTUnwrap(state["currentMapId"] as? String),
            x: try XCTUnwrap(spatial["x"] as? NSNumber).doubleValue,
            z: try XCTUnwrap(spatial["z"] as? NSNumber).doubleValue
        )
        XCTAssertEqual(spatial["schemaVersion"] as? Int, 1)
        XCTAssertEqual(grid["x"] as? Int, Int(floor(pose.x)))
        XCTAssertEqual(grid["y"] as? Int, Int(floor(pose.z)))
        let snapshot = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        snapshot.name = "spatial-ios-save-\(name)-readonly-envelope"
        snapshot.lifetime = .keepAlways
        add(snapshot)
        let back = button(["Retour", "Back"], in: app)
        try require(back.waitForExistence(timeout: 5) && back.isHittable, "Le reçu doit permettre de revenir au menu.", app)
        back.tap()
        let resume = app.buttons["pause-frame-return"].firstMatch
        try require(resume.waitForExistence(timeout: 5) && resume.isHittable, "Le menu doit reprendre la partie après sa sauvegarde.", app)
        resume.tap()
        try require(app.buttons["Menu"].firstMatch.waitForExistence(timeout: 10), "La vue jouable doit revenir après la sauvegarde.", app)
        return pose
    }

    private func button(_ labels: [String], in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
    }

    private func require(_ condition: Bool, _ message: String, _ app: XCUIApplication) throws {
        if condition { return }
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "spatial-ios-failure-accessibility-tree"
        tree.lifetime = .keepAlways
        add(tree)
        attachScreenshot(app, name: "spatial-ios-failure")
        XCTFail(message)
        throw SpatialGateFailure.unexpectedSurface(message)
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private enum SpatialGateFailure: Error {
    case unexpectedSurface(String)
}

private struct SpatialSavedPose {
    let mapId: String
    let x: Double
    let z: Double
}

private struct SpatialDurabilityConfiguration {
    let bundleId: String
    let packageName: String
    let gameTitle: String
    let expectedDialogue: String
    let documentsFolderName: String
}
