import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/app/app_root.dart';
import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/app/di/hub_composition_provider.dart';
import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/data/sources/file_package_source.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('The spatial Hub harness requires a macOS debug build.');
  }
  MarionetteBinding.ensureInitialized();
  final supportRoot = await _ownedSupportRoot();
  final package = await _configuredPackage();
  final container = ProviderContainer(
    overrides: [supportRootProvider.overrideWith((ref) async => supportRoot)],
  );
  final composition = await container.read(hubCompositionProvider.future);
  if (composition is! HubComposition) {
    throw StateError('The native Hub composition is unavailable.');
  }
  await composition.controller.initialize();
  GamePackageManifest? importedManifest;
  if (package != null) {
    final source = await FilePackageSource.open(package);
    try {
      importedManifest = GamePackageInspector(
        hostCompatibility: aveluneHostCompatibility(),
      ).inspectSourceSync(source).manifest;
    } finally {
      await source.close();
    }
    await composition.controller.importPackage(package);
    final installed = composition.controller.snapshot.games.where(
      (entry) => entry.game.gameId == importedManifest!.gameId,
    );
    if (composition.controller.snapshot.safeErrorMessage != null ||
        installed.length != 1 ||
        !installed.single.activity.installationHealthy ||
        installed.single.game.current.gameVersion !=
            importedManifest.gameVersion ||
        installed.single.game.current.treeSha256 !=
            importedManifest.content.treeSha256) {
      throw StateError(
        'The native Hub did not install the configured package: '
        '${composition.controller.snapshot.safeErrorMessage}',
      );
    }
  }
  final identities = <String, GameIdentity>{};
  registerMarionetteExtension(
    name: 'spatialHub.context',
    description: 'Observes the real Hub, spatial session and durable save.',
    callback: (_) async {
      final mounted = _mountedPlayer();
      final player = mounted.player?.controller.snapshot;
      final runtime = mounted.runtime;
      final session = mounted.spatial?.session;
      final activeGame = composition.sessionController.activeGame?.game;
      Map<String, Object?>? saved;
      Object? saveError;
      if (activeGame != null) {
        try {
          final key = '${activeGame.gameId}#${activeGame.current.treeSha256}';
          var identity = identities[key];
          if (identity == null) {
            identity = (await composition.launchResolver.resolve(
              activeGame,
            )).identity;
            identities[key] = identity;
          }
          final store = HubSaveStore(
            supportRoot: supportRoot,
            identity: identity,
          );
          final address = player?.activeSaveAddress;
          final read = address != null && address.gameId == activeGame.gameId
              ? await store.read(
                  SaveSlotAddress(
                    gameId: address.gameId,
                    profileId: address.profileId,
                    slotId: address.slotId,
                  ),
                )
              : await store.findContinue();
          final envelope = read?.envelope;
          saved = {
            'status': read?.status.name,
            'source': read?.source?.name,
            'address': read == null
                ? null
                : {
                    'gameId': read.address.gameId,
                    'profileId': read.address.profileId,
                    'slotId': read.address.slotId,
                  },
            'saveId': envelope?.saveId,
            'updatedAt': envelope?.updatedAt.toIso8601String(),
            'state': envelope == null
                ? null
                : _stateContext(
                    const GameStateSaveEnvelopeMapper().restore(envelope),
                  ),
          };
        } on Object catch (error) {
          saveError = error;
        }
      }
      final current = _mountedPlayer();
      final unchanged =
          identical(mounted.runtime, current.runtime) &&
          identical(session, current.spatial?.session);
      final movement = unchanged ? session?.movement : null;
      final interaction = unchanged
          ? runtime?.overworldInteractionSnapshot
          : null;
      final dialogue = unchanged ? session?.dialoguePresentation.value : null;
      final view = WidgetsBinding.instance.platformDispatcher.implicitView;
      return MarionetteExtensionResult.success({
        'pid': pid,
        'supportRoot': supportRoot.path,
        'packagePath': package?.path,
        'importedGameId': importedManifest?.gameId,
        'importedTreeSha256': importedManifest?.content.treeSha256,
        'surface': composition.sessionController.surface.name,
        'dashboardStatus': composition.controller.snapshot.status.name,
        'dashboardError': composition.controller.snapshot.safeErrorMessage,
        'activeGameId': composition.sessionController.activeGame?.game.gameId,
        'installedGames': [
          for (final entry in composition.controller.snapshot.games)
            {
              'gameId': entry.game.gameId,
              'title': entry.game.title,
              'pointer': entry.game.current.toJson(),
              'healthy': entry.activity.installationHealthy,
            },
        ],
        'playerPhase': player?.phase.name,
        'playerRevision': player?.revision,
        'pauseSection': player?.pauseSection?.name,
        'playerFailure': player?.failure?.code.name,
        'spatialMounted': current.spatial != null,
        'ownerChangedDuringRead': !unchanged,
        'sessionId': interaction?.sessionId,
        'mapActivationId': interaction?.mapActivationId,
        'projectRoot': unchanged ? session?.bundle.projectRootDirectory : null,
        'projectFilePath': unchanged && session != null
            ? p.join(session.bundle.projectRootDirectory, 'project.json')
            : null,
        'mapId': unchanged ? session?.bundle.map.id : null,
        'position': movement?.spatialPosition.toJson(),
        'gridPosition': movement == null
            ? null
            : {'x': movement.x.floor(), 'y': movement.z.floor()},
        'height': movement?.y,
        'facing': movement?.facing.name,
        'moving': movement?.moving,
        'inputPaused': movement?.paused,
        'inputEpoch': movement?.inputEpoch,
        'inputContext': unchanged
            ? runtime?.inputAuthority.value.context.name
            : null,
        'inputLocks': unchanged
            ? runtime?.inputAuthority.value.externalLocks
                  .map((lock) => lock.name)
                  .toList()
            : null,
        'transitioning': unchanged ? session?.transitioning.value : null,
        'interaction': interaction?.primaryAction?.toJson(),
        'dialogue': dialogue == null
            ? null
            : {
                'revision': dialogue.revision,
                'mode': dialogue.mode.name,
                'speaker': dialogue.speaker,
                'text': dialogue.text,
                'fullText': dialogue.fullText,
                'revealed': dialogue.isCurrentLineFullyRevealed,
                'choices': [
                  for (final choice in dialogue.choices)
                    {
                      'index': choice.index,
                      'label': choice.label,
                      'selected': choice.selected,
                      'enabled': choice.enabled,
                    },
                ],
              },
        'interactionError': unchanged
            ? session?.interactionError.value?.toString()
            : null,
        'battlePhase': unchanged ? runtime?.battle?.phase.name : null,
        'battleError': unchanged ? runtime?.battle?.error?.toString() : null,
        'gameState': unchanged && runtime != null
            ? _stateContext(runtime.gameStateSnapshot)
            : null,
        'saved': saved,
        'saveError': saveError?.toString(),
        'devicePixelRatio': view?.devicePixelRatio,
        'logicalSize': view == null
            ? null
            : {
                'width': view.physicalSize.width / view.devicePixelRatio,
                'height': view.physicalSize.height / view.devicePixelRatio,
              },
      });
    },
  );
  registerMarionetteExtension(
    name: 'spatialHub.input',
    description: 'Routes a bounded real control press to the mounted session.',
    callback: (parameters) async {
      final mounted = _mountedPlayer();
      final runtime = mounted.runtime;
      final route = mounted.player?.gameplayInputRoute;
      final interaction = runtime?.overworldInteractionSnapshot;
      if (runtime == null || route == null || interaction == null) {
        return const MarionetteExtensionResult.error(
          0,
          'No spatial runtime input owner is mounted.',
        );
      }
      if (!p.isWithin(
        supportRoot.path,
        runtime.session!.bundle.projectRootDirectory,
      )) {
        return const MarionetteExtensionResult.error(
          0,
          'The mounted spatial project is outside the owned Hub installation.',
        );
      }
      if (parameters['sessionId'] != interaction.sessionId ||
          parameters['mapActivationId'] != interaction.mapActivationId) {
        return const MarionetteExtensionResult.invalidParams(
          'Expected sessionId and mapActivationId must match spatialHub.context.',
        );
      }
      final controls = RuntimeInputControl.values.where(
        (control) => control.name == parameters['control'],
      );
      final phase = parameters['phase'] ?? 'press';
      final holdMs = int.tryParse(parameters['holdMs'] ?? '70');
      if (controls.length != 1 ||
          controls.single == RuntimeInputControl.menu ||
          !{'press', 'release'}.contains(phase) ||
          holdMs == null ||
          holdMs < 10 ||
          holdMs > 1500) {
        return const MarionetteExtensionResult.invalidParams(
          'Use a gameplay control, press/release, and holdMs between 10 and 1500. '
          'Open menus through the native player UI or keyboard.',
        );
      }
      final control = controls.single;
      if (phase == 'release') {
        return MarionetteExtensionResult.success({
          'accepted': route(RuntimeInputEvent.release(control)),
          'control': control.name,
          'phase': phase,
        });
      }
      bool accepted;
      try {
        accepted = route(RuntimeInputEvent.press(control));
        await Future<void>.delayed(Duration(milliseconds: holdMs));
      } finally {
        runtime.handleInput(RuntimeInputEvent.release(control));
      }
      return MarionetteExtensionResult.success({
        'accepted': accepted,
        'control': control.name,
        'phase': phase,
        'holdMs': holdMs,
        'released': true,
      });
    },
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: _PackagedHubAssets(rootBundle),
        child: const PokeMapHubBootstrap(),
      ),
    ),
  );
}

final class _PackagedHubAssets extends CachingAssetBundle {
  _PackagedHubAssets(this.source);

  final AssetBundle source;

  @override
  Future<ByteData> load(String key) => source.load(
      key.startsWith('assets/avelune/') ? 'packages/pokemap_hub/$key' : key);
}

Map<String, Object?> _stateContext(GameState state) => {
  'saveId': state.saveId,
  'mapId': state.currentMapId,
  'gridPosition': state.playerPosition.toJson(),
  'position': state.playerSpatialPosition?.toJson(),
  'facing': state.playerFacing.name,
  'trainer': state.trainerProfile.toJson(),
  'bag': state.bag.toJson(),
  'party': [
    for (final member in state.party.members)
      {
        'individualId': member.individualId,
        'speciesId': member.speciesId,
        'level': member.level,
        'hp': member.currentHp,
      },
  ],
  'facts': state.narrativeFactRuntimeState.overridesByFactId,
  'storyFlags': state.storyFlags.toJson(),
};

Future<Directory> _ownedSupportRoot() async {
  const configuredPath = String.fromEnvironment('MARIONETTE_SUPPORT_ROOT');
  if (configuredPath.isEmpty || !p.isAbsolute(configuredPath)) {
    throw StateError('MARIONETTE_SUPPORT_ROOT must be an absolute directory.');
  }
  if (await FileSystemEntity.type(configuredPath, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw StateError('The support root must exist without a symlink.');
  }
  final canonical = await Directory(configuredPath).resolveSymbolicLinks();
  final temporaryRoot = await Directory('/tmp').resolveSymbolicLinks();
  if (p.normalize(configuredPath) != canonical ||
      !p.isWithin(temporaryRoot, canonical) ||
      !p.basename(canonical).startsWith('avelune-spatial-hub-')) {
    throw StateError(
      'The support root must be a canonical owned temp directory.',
    );
  }
  final marker = File(p.join(canonical, '.spatial-hub-marionette-owner'));
  if (await FileSystemEntity.type(marker.path, followLinks: false) !=
          FileSystemEntityType.file ||
      (await marker.readAsString()).trim() != 'spatial-hub-marionette@1') {
    throw StateError('The spatial Hub ownership marker is missing.');
  }
  return Directory(canonical);
}

Future<File?> _configuredPackage() async {
  const configuredPath = String.fromEnvironment('MARIONETTE_GAME_PACKAGE');
  if (configuredPath.isEmpty) return null;
  if (!p.isAbsolute(configuredPath) ||
      p.extension(configuredPath).toLowerCase() != '.avelunegame' ||
      await FileSystemEntity.type(configuredPath, followLinks: false) !=
          FileSystemEntityType.file ||
      p.normalize(configuredPath) !=
          await File(configuredPath).resolveSymbolicLinks()) {
    throw StateError(
      'MARIONETTE_GAME_PACKAGE must be a canonical package file.',
    );
  }
  return File(configuredPath);
}

({
  PokeMapPlayerSessionView? player,
  SpatialExplorationView? spatial,
  SpatialExplorationGameSessionRuntime? runtime,
})
_mountedPlayer() {
  PokeMapPlayerSessionView? player;
  SpatialExplorationView? spatial;
  SpatialExplorationGameSessionRuntime? runtime;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is PokeMapPlayerSessionView) {
      if (player != null && !identical(player, widget)) {
        throw StateError('More than one player session is mounted.');
      }
      player = widget;
    }
    if (widget is SpatialExplorationView) {
      if (spatial != null && !identical(spatial, widget)) {
        throw StateError('More than one spatial session is mounted.');
      }
      final key = widget.key;
      if (key is! ObjectKey ||
          key.value is! SpatialExplorationGameSessionRuntime ||
          !identical(
            (key.value as SpatialExplorationGameSessionRuntime).session,
            widget.session,
          )) {
        throw StateError('The spatial view has no matching runtime owner.');
      }
      spatial = widget;
      runtime = key.value as SpatialExplorationGameSessionRuntime;
    }
    element.visitChildElements(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildElements(visit);
  return (player: player, spatial: spatial, runtime: runtime);
}
