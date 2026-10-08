import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'studio_playtest_session.dart';

final class StudioSpatialPlaytest {
  StudioSpatialPlaytest._(this.runtime, this.saves);

  final SpatialExplorationGameSessionRuntime runtime;
  final StudioPlaytestSession saves;

  static void validateHero(RuntimeMapBundle bundle) {
    final id = bundle.manifest.settings.defaultPlayerCharacterId;
    final hero = bundle.manifest.characters
        .where((character) => character.id == id)
        .firstOrNull;
    if (hero == null || hero.animations.isEmpty) {
      throw StateError(
        'Choisissez un héros animé dans les réglages du projet.',
      );
    }
  }

  static Future<StudioSpatialPlaytest> prepare({
    required RuntimeMapBundle bundle,
    required String projectFilePath,
    required String projectRevision,
    required StudioPlaytestSession saves,
    bool restore = false,
    SpatialExplorationSessionMount? mountSession,
    SpatialExplorationSessionMount? unmountSession,
  }) async {
    validateHero(bundle);
    final project = bundle.manifest;
    if (!project.newGame.enabled) {
      throw StateError(
        'Configurez la nouvelle partie et son point de départ dans les réglages du projet avant de tester le jeu 3D.',
      );
    }
    final identity = GameIdentity(
      gameId: 'games.avelune.studio-playtest',
      gameVersion: '0.0.0',
      projectFormat: ProjectFormat.parse(project.version.name),
      saveFormat: SaveEnvelopeCodec.currentSaveFormat,
      compatibilityId: 'studio-spatial',
    );
    final launchId = 'studio-${DateTime.now().microsecondsSinceEpoch}';
    SaveEnvelope? initialSave;
    GameState? initialState;
    var mode = GameSessionLaunchMode.newGame;
    if (restore) {
      initialSave = saves.spatialSave;
      if (initialSave == null) {
        throw StateError('Aucune sauvegarde de test à reprendre.');
      }
      mode = GameSessionLaunchMode.continueGame;
    } else {
      final authored = bundle.map.id == project.newGame.startMapId
          ? bundle
          : await loadRuntimeMapBundle(
              projectFilePath: projectFilePath,
              mapId: project.newGame.startMapId,
            );
      var draft = NewGameDraft.start(
        draftId: '$launchId-draft',
        projectRevision: projectRevision,
        slotId: 'test',
        config: project.newGame,
      );
      if (draft.allowedAvatarCharacterIds.length == 1) {
        draft = draft
            .apply(
              NewGameDraftCommand.selectAvatar(
                expectedRevision: draft.revision,
                avatarCharacterId: draft.allowedAvatarCharacterIds.single,
              ),
            )
            .draft;
      }
      if (draft.allowedStarterOptionIds.length == 1) {
        draft = draft
            .apply(
              NewGameDraftCommand.selectStarter(
                expectedRevision: draft.revision,
                starterOptionId: draft.allowedStarterOptionIds.single,
              ),
            )
            .draft;
      }
      final committed = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: '$launchId-seed',
        currentProjectRevision: projectRevision,
        expectedDraftRevision: draft.revision,
        draft: draft,
      );
      if (committed.seed == null) {
        throw StateError(
          'La configuration de départ est incomplète. Choisissez un héros et un starter uniques pour le test direct de la carte.',
        );
      }
      initialState = createNewGameStateFromSeed(
        project: project,
        startMap: authored.map,
        seed: committed.seed!,
        currentProjectRevision: projectRevision,
        locale: 'fr',
        tileWidthPx: project.settings.tileWidth,
        tileHeightPx: project.settings.tileHeight,
      );
      if (bundle.map.id != initialState.currentMapId) {
        final movement = SpatialMovementController.fromMap(
          map: bundle.map,
          models: project.models3d,
        );
        initialState = initialState.copyWith(
          currentMapId: bundle.map.id,
          playerPosition: GridPos(x: movement.x.floor(), y: movement.z.floor()),
          playerSpatialPosition: movement.spatialPosition,
          playerFacing: movement.facing,
        );
        final now = DateTime.now().toUtc();
        initialSave = saves.spatialEnvelope(
          identity: identity,
          checkpoint: GameSessionCheckpoint(
            saveId: initialState.saveId,
            createdAt: now,
            updatedAt: now,
            playTimeSeconds: 0,
            state: strictGameStateSaveJson(initialState),
          ),
        );
        initialState = null;
        mode = GameSessionLaunchMode.load;
      }
    }
    final initialMap = initialSave == null
        ? bundle
        : const GameStateSaveEnvelopeMapper()
                  .restore(initialSave)
                  .currentMapId ==
              bundle.map.id
        ? bundle
        : await loadRuntimeMapBundle(
            projectFilePath: projectFilePath,
            mapId: const GameStateSaveEnvelopeMapper()
                .restore(initialSave)
                .currentMapId,
          );
    final runtime = SpatialExplorationGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: launchId,
        sessionToken: '$launchId-token',
        identity: identity,
        profileId: 'studio',
        slotId: 'test',
        launchMode: mode,
        installedVersionHandle: '$launchId-project',
        saveReadHandle: initialSave == null ? null : '$launchId-save',
        runtimeApiVersion: '1',
        grantedCapabilities: const {
          'map3d@1',
          SpatialGameplayCapabilities.capabilityId,
          SpatialGameplayCapabilities.storyCapabilityId,
          'map3d.animation@1',
        },
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
        initialGameState: initialState,
      ),
      projectFilePath: () async => projectFilePath,
      initialSave: initialSave == null ? null : () async => initialSave,
      preloadedInitialMap:
          ({
            required projectFilePath,
            required descriptor,
            required initialSave,
          }) async => RuntimeInitialMapPreloadResult(bundle: initialMap),
      mountSession: mountSession ?? (_) async {},
      unmountSession: unmountSession ?? (_) async {},
      commitCheckpoint: (request) => saves.saveSpatialCheckpoint(
        identity: identity,
        checkpoint: request.checkpoint,
        status: request.status,
        completedAt: request.completedAt,
      ),
    );
    return StudioSpatialPlaytest._(runtime, saves);
  }

  Future<bool> save() async {
    final checkpoint = await runtime.captureCheckpoint();
    if (checkpoint == null) return false;
    await saves.saveSpatialCheckpoint(
      identity: runtime.descriptor.identity,
      checkpoint: checkpoint,
    );
    return true;
  }

  Future<void> dispose() => runtime.dispose();
}
