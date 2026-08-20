import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// Hôte partagé des golden gates de domaine — BETA-SYS-007 / BETA-PTY-005.
///
/// Extrait du parcours de la gate de démarrage pour que chaque gate de domaine
/// n'ait plus qu'à écrire SON journey : export de la fixture, installation,
/// suppression de l'espace auteur et de l'archive (l'herméticité), résolution
/// du lancement, coordinateur joueur complet, et les gestes communs — nouvelle
/// partie, pause, sauvegarde, retour au titre, reprise.
final class GoldenGateHost {
  GoldenGateHost._({
    required this.sessions,
    required this.coordinator,
    required this.profileId,
    required this.slotId,
    required PlayableMapGame? Function() mountedGame,
  }) : _mountedGame = mountedGame;

  final GameSessionController sessions;
  final RuntimePlayerCoordinator coordinator;
  final String profileId;
  final String slotId;
  final PlayableMapGame? Function() _mountedGame;

  PlayableMapGame get mounted {
    final game = _mountedGame();
    if (game == null) {
      throw StateError('No game is mounted at this point of the journey.');
    }
    return game;
  }

  static Future<GoldenGateHost> launch({
    required NeutralCertificationGameFixture fixture,
    required Directory root,
    required String profileId,
    required String slotId,
  }) async {
    final authorRoot = Directory(p.join(root.path, 'author'));
    final supportRoot = Directory(p.join(root.path, 'support'));
    final packageFile = File(p.join(root.path, 'neutral.avelunegame'));
    await fixture.writeAuthorWorkspace(authorRoot);
    await fixture.export(authorRoot, packageFile);
    final installed = await _installer(
      supportRoot: supportRoot,
      fixture: fixture,
    ).install(packageFile, source: GamePackageInstallSource.localExport);
    // L'herméticité : plus rien ne peut être lu hors de la version installée.
    await authorRoot.delete(recursive: true);
    await packageFile.delete();

    final launch = await InstalledGameLaunchResolver(
      supportRoot: supportRoot,
      hostCompatibility: fixture.hostCompatibility,
    ).resolve(installed.game);
    final projectFile = await launch.assets.resolveReference(launch.project);

    final store = HubSaveStore(
      supportRoot: supportRoot,
      identity: launch.identity,
    );
    final saveGateway = HubPlayerSaveGateway(store: store);
    final preferences = HubPlayerPreferencesGateway(
      store: _MemoryPreferencesStore(),
      fallbackLocale: 'en',
    );
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: saveGateway.readLaunchableEnvelope,
    );
    PlayableMapGame? mounted;
    final sessions = GameSessionController(
      adapterFactory: HubInProcessSessionFactory(
        launch: launch,
        saves: store,
        mountGame: (game) async => mounted = game,
        unmountGame: (_) async => mounted = null,
        preloadedInitialMap: preloader.resolveForSession,
      ).call,
      commitCheckpoint: saveGateway.commit,
    );
    final coordinator = RuntimePlayerCoordinator(
      gameSource: HubRuntimeGameSource(
        launch: launch,
        preferencesGateway: preferences,
      ),
      saveGateway: saveGateway,
      preferencesGateway: preferences,
      newGameFlow: RuntimeProjectNewGameFlowPort(
        projectFilePath: () async => projectFile.path,
        initialMapPreloader: preloader,
      ),
      sessionController: sessions,
      externalExit: HubRuntimeExternalExit(() async {}),
    );
    final host = GoldenGateHost._(
      sessions: sessions,
      coordinator: coordinator,
      profileId: profileId,
      slotId: slotId,
      mountedGame: () => mounted,
    );
    await coordinator.initialize();
    expect(coordinator.snapshot.phase, RuntimePlayerPhase.title);
    return host;
  }

  Future<RuntimePlayerCommandResult> dispatchPlayer(
    RuntimePlayerAction action, {
    Object? payload,
  }) {
    return coordinator.dispatch(
      RuntimePlayerCommand(
        action: action,
        snapshotRevision: coordinator.snapshot.revision,
        payload: payload,
      ),
    );
  }

  Future<void> startNewGame() async {
    final result = await dispatchPlayer(
      RuntimePlayerAction.newGame,
      payload: RuntimePlayerLoadSlot(profileId: profileId, slotId: slotId),
    );
    expect(result.status, RuntimePlayerCommandStatus.accepted);
    await waitForPhase(RuntimePlayerPhase.playing);
  }

  Future<void> continueGame() async {
    final result = await dispatchPlayer(
      RuntimePlayerAction.continueGame,
      payload: RuntimePlayerLoadSlot(profileId: profileId, slotId: slotId),
    );
    expect(result.status, RuntimePlayerCommandStatus.accepted);
    await waitForPhase(RuntimePlayerPhase.playing);
  }

  Future<void> openPause() async {
    final opened = await dispatchPlayer(RuntimePlayerAction.openMenu);
    expect(opened.status, RuntimePlayerCommandStatus.accepted);
    expect(coordinator.snapshot.phase, RuntimePlayerPhase.paused);
  }

  Future<void> openPartySection() async {
    final opened = await dispatchPlayer(RuntimePlayerAction.openParty);
    expect(opened.status, RuntimePlayerCommandStatus.accepted);
  }

  Future<void> resume() async {
    final resumed = await dispatchPlayer(RuntimePlayerAction.resume);
    expect(resumed.status, RuntimePlayerCommandStatus.accepted);
    await waitForPhase(RuntimePlayerPhase.playing);
  }

  Future<void> returnToTitle() async {
    final left = await dispatchPlayer(RuntimePlayerAction.returnToTitle);
    expect(left.status, RuntimePlayerCommandStatus.accepted);
    await waitForPhase(RuntimePlayerPhase.title);
  }

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceAction action, {
    String? targetId,
    String? secondaryTargetId,
  }) async {
    final snapshot = sessions.worldServiceSnapshot;
    if (snapshot == null) {
      throw StateError('No world service is active.');
    }
    final result = await sessions.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
        secondaryTargetId: secondaryTargetId,
      ),
    );
    if (result.status == RuntimeWorldServiceCommandStatus.accepted &&
        action != RuntimeWorldServiceAction.close &&
        action != RuntimeWorldServiceAction.cancel) {
      // La republication du snapshot traverse un stream : une vraie surface
      // attend la révision fraîche avant la commande suivante, l'hôte aussi —
      // sinon la commande suivante part périmée et le service la refuse.
      // Deux publications par transfert : le stage « applying » d'abord, le
      // snapshot final ensuite. Attendre la première ferait partir la commande
      // suivante avec une révision intermédiaire déjà périmée.
      for (var attempt = 0; attempt < 2000; attempt++) {
        final current = sessions.worldServiceSnapshot;
        if (current == null ||
            (current.revision > snapshot.revision &&
                current.stage != RuntimeWorldServiceStage.applying)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }
    return result;
  }

  Future<void> waitForWorldService() async {
    for (var attempt = 0; attempt < 2000; attempt++) {
      if (sessions.worldServiceSnapshot != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail('No world service snapshot was ever published.');
  }

  Future<void> waitForPhase(RuntimePlayerPhase phase) async {
    for (var attempt = 0; attempt < 2000; attempt++) {
      if (coordinator.snapshot.phase == phase) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail(
      'the player never reached $phase, '
      'last phase was ${coordinator.snapshot.phase}',
    );
  }

  Future<void> dispose() async {
    await coordinator.dispose();
  }
}

final class _MemoryPreferencesStore
    implements PlayerPreferencesRepositoryInterface {
  PlayerPreferences _preferences = const PlayerPreferences();

  @override
  Future<HubPreferencesRead> load() async => HubPreferencesRead(
        preferences: _preferences,
        source: HubPreferencesSource.defaults,
        currentCorrupt: false,
        backupCorrupt: false,
      );

  @override
  Future<void> save(PlayerPreferences preferences) async {
    _preferences = preferences;
  }
}

GamePackageInstaller _installer({
  required Directory supportRoot,
  required NeutralCertificationGameFixture fixture,
}) =>
    GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: fixture.hostCompatibility,
      ),
      availableDiskBytes: (_) async => 1024 * 1024 * 1024,
      prepareSavesForUpdate: (_, __) async =>
          const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
      loadSmoke: (stagedVersionRoot, manifest) async {
        final projectFile = File(
          p.join(stagedVersionRoot.path, 'project', 'project.json'),
        );
        final decoded = jsonDecode(await projectFile.readAsString());
        final project =
            ProjectManifest.fromJson(decoded as Map<String, dynamic>);
        await loadRuntimeMapBundle(
          projectFilePath: projectFile.path,
          mapId: project.newGame.startMapId,
        );
      },
    );
