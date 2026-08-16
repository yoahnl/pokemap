import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CIN-042 exports, installs and plays Presentation before save reload',
    () async {
      final root = await Directory.systemTemp.createTemp('cin042-canary-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final authorRoot = Directory(p.join(root.path, 'author'));
      final supportRoot = Directory(p.join(root.path, 'support'));
      final packageFile = File(p.join(root.path, 'cin042.avelunegame'));
      await _writeAuthorProject(authorRoot);
      stdout.writeln('cin042:author-ready');

      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: authorRoot,
        profile: _exportProfile,
        outputFile: packageFile,
      );
      stdout.writeln('cin042:export-ready');
      final compatibility = _hostCompatibility(
        artifact.manifest.compatibility.requiredCapabilities,
      );
      final installed = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(hostCompatibility: compatibility),
        availableDiskBytes: (_) async => 1024 * 1024 * 1024,
        prepareSavesForUpdate: (_, __) async =>
            const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
        loadSmoke: (versionRoot, _) async {
          final projectFile = File(
            p.join(versionRoot.path, 'project', 'project.json'),
          );
          final bundle = await loadRuntimeMapBundle(
            projectFilePath: projectFile.path,
            mapId: 'map.start',
          );
          expect(bundle.map.id, 'map.start');
        },
      ).install(packageFile, source: GamePackageInstallSource.localExport);
      await authorRoot.delete(recursive: true);

      final bootstrap = HubRuntimeStartupBootstrap(
        supportRoot: supportRoot,
        saveRepositoryFactory: (root, identity) =>
            HubSaveStore(supportRoot: root, identity: identity),
        preferencesRepository: _PreferencesRepository(),
        controlProfileRepository: _ControlProfileRepository(),
        launchResolver: InstalledGameLaunchResolver(
          supportRoot: supportRoot,
          hostCompatibility: compatibility,
        ),
        game: installed.game,
        onHubRequested: () async {},
        mountGame: (_) async {},
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Player',
        presentationFrameDeltas: (durationUs) => Stream<int>.value(durationUs),
        presentationBeforeTerminal: () async {},
      );
      stdout.writeln('cin042:install-ready');
      final prepared = await bootstrap.prepare(onStageCompleted: (_) {});
      stdout.writeln('cin042:bootstrap-ready');
      final data = prepared.value;
      addTearDown(() async {
        await data.coordinator.dispose();
        await data.presentationRuntime?.close();
      });
      await data.coordinator.initialize();
      stdout.writeln('cin042:title-ready');

      final launch = data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      await _waitUntil(
        () => data.coordinator.snapshot.preSessionRequest != null,
      );
      stdout.writeln('cin042:interaction-ready');
      expect(
        data.presentationRuntime?.controller.lastReceipt?.terminal.outcome,
        PresentationExecutionOutcome.completed,
      );
      final request = data.coordinator.snapshot.preSessionRequest!;
      final resolution = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.resolvePreSessionInteraction,
          snapshotRevision: data.coordinator.snapshot.revision,
          payload: SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: 'Yoahn',
          ),
        ),
      );
      expect(resolution.status, RuntimePlayerCommandStatus.accepted);
      final launchResult = await launch;
      expect(
        launchResult.status,
        RuntimePlayerCommandStatus.accepted,
        reason:
            '${launchResult.safeMessage} session=${data.sessions.snapshot.failure?.safeMessage} state=${data.sessions.snapshot.state}',
      );
      stdout.writeln('cin042:launch-ready');
      await _waitUntil(
        () => data.coordinator.snapshot.phase == RuntimePlayerPhase.playing,
      );

      final paused = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.openMenu,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(paused.status, RuntimePlayerCommandStatus.accepted);
      final saved = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.save,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(
        saved.status,
        RuntimePlayerCommandStatus.accepted,
        reason: saved.safeMessage,
      );
      stdout.writeln('cin042:save-ready');
      final returned = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.returnToTitle,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(returned.status, RuntimePlayerCommandStatus.accepted);
      stdout.writeln('cin042:title-returned');
      final continued = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.continueGame,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(continued.status, RuntimePlayerCommandStatus.accepted);
      stdout.writeln('cin042:continue-ready');
      await _waitUntil(
        () => data.coordinator.snapshot.phase == RuntimePlayerPhase.playing,
      );

      final pausedBeforeCrash = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.openMenu,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(pausedBeforeCrash.status, RuntimePlayerCommandStatus.accepted);
      final returnedBeforeCrash = await data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.returnToTitle,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      expect(returnedBeforeCrash.status, RuntimePlayerCommandStatus.accepted);
      final savesBeforeCrash = await _snapshotFiles(
        Directory(p.join(supportRoot.path, 'saves')),
      );
      final interruptedLaunch = data.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: data.coordinator.snapshot.revision,
        ),
      );
      await _resolveOverwriteConfirmation(data.coordinator);
      await _waitForInteractionKind(
        data.coordinator,
        SceneInteractionRequestKind.text,
      );
      final interruptedRunId =
          data.presentationRuntime?.controller.lastReceipt?.correlation.runId;
      expect(interruptedRunId, isNotEmpty);
      await data.coordinator.dispose();
      await data.presentationRuntime?.close();
      expect(
        (await interruptedLaunch).status,
        RuntimePlayerCommandStatus.cancelled,
      );
      expect(
        await _snapshotFiles(Directory(p.join(supportRoot.path, 'saves'))),
        savesBeforeCrash,
      );

      final restarted = (await bootstrap.prepare(
        onStageCompleted: (_) {},
      )).value;
      addTearDown(() async {
        await restarted.coordinator.dispose();
        await restarted.presentationRuntime?.close();
      });
      await restarted.coordinator.initialize();
      final restartedLaunch = restarted.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: restarted.coordinator.snapshot.revision,
        ),
      );
      await _resolveOverwriteConfirmation(restarted.coordinator);
      await _waitForInteractionKind(
        restarted.coordinator,
        SceneInteractionRequestKind.text,
      );
      expect(
        restarted
            .presentationRuntime
            ?.controller
            .lastReceipt
            ?.correlation
            .runId,
        isNot(interruptedRunId),
      );
      final cancelled = await restarted.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.cancel,
          snapshotRevision: restarted.coordinator.snapshot.revision,
        ),
      );
      expect(cancelled.status, RuntimePlayerCommandStatus.accepted);
      expect(
        (await restartedLaunch).status,
        RuntimePlayerCommandStatus.cancelled,
      );
      expect(
        await _snapshotFiles(Directory(p.join(supportRoot.path, 'saves'))),
        savesBeforeCrash,
      );

      expect(artifact.certification.isCertified, isTrue);
      expect(
        artifact.inspection.payloadPaths,
        contains('project/assets/.pokemap-media.json'),
      );
      expect(
        artifact.inspection.payloadPaths.any(
          (path) =>
              path.startsWith('project/assets/.pokemap-store/') &&
              path.endsWith('.blob'),
        ),
        isTrue,
      );
      expect(installed.receipt.packageSha256, artifact.packageSha256);
      expect(
        data.presentationRuntime?.controller.lastReceipt?.correlation.runId,
        isNotEmpty,
      );
    },
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200 && !predicate(); attempt += 1) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(predicate(), isTrue);
}

Future<void> _waitForInteractionKind(
  RuntimePlayerCoordinator coordinator,
  SceneInteractionRequestKind kind,
) async {
  await _waitUntil(() => coordinator.snapshot.preSessionRequest?.kind == kind);
}

Future<void> _resolveOverwriteConfirmation(
  RuntimePlayerCoordinator coordinator,
) async {
  await _waitForInteractionKind(
    coordinator,
    SceneInteractionRequestKind.confirmation,
  );
  final snapshot = coordinator.snapshot;
  final request = snapshot.preSessionRequest!;
  final result = await coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.resolvePreSessionInteraction,
      snapshotRevision: snapshot.revision,
      payload: SceneInteractionResult.confirmed(
        requestId: request.requestId,
        revision: request.revision,
        value: true,
      ),
    ),
  );
  expect(result.status, RuntimePlayerCommandStatus.accepted);
}

Future<Map<String, String>> _snapshotFiles(Directory root) async {
  if (!await root.exists()) return const <String, String>{};
  final files = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return <String, String>{
    for (final file in files)
      p.relative(file.path, from: root.path): base64Encode(
        await file.readAsBytes(),
      ),
  };
}

Future<void> _writeAuthorProject(Directory root) async {
  await Directory(p.join(root.path, 'maps')).create(recursive: true);
  await File(
    p.join(root.path, 'project.json'),
  ).writeAsString(jsonEncode(_project().toJson()), flush: true);
  await File(p.join(root.path, 'maps', 'start.json')).writeAsString(
    jsonEncode(
      const MapData(
        id: 'map.start',
        name: 'Start',
        version: ProjectVersion.v6,
        size: GridSize(width: 2, height: 2),
        mapMetadata: MapMetadata(defaultSpawnId: 'spawn.player'),
        entities: <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            name: 'Player',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 0, y: 0),
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
      ).toJson(),
    ),
    flush: true,
  );
  await File(p.join(root.path, 'LICENSE.txt')).writeAsString('CIN-042');
  await SeedPokemonDemoDataUseCase(
    snapshotController: FilePokemonReadRepository(),
  ).execute(ProjectFileSystem(root.path));
  await _writeReferencedPokemonAssets(root);
  await _writePresentationMediaAssets(root);
}

Future<void> _writePresentationMediaAssets(Directory root) async {
  final artifact = ContentArtifactRef.fromBytes(
    _onePixelPng,
    mediaType: 'image/png',
  );
  final assetCatalog = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'asset.opening.image',
        logicalPath: 'presentation/opening.png',
        artifact: artifact,
        usages: const <String>['presentation:opening'],
        tags: const <String>['presentation'],
      ),
    ],
  );
  final mediaCatalog = ProjectMediaCatalog(
    entries: <ProjectMediaAsset>[
      ProjectMediaAsset(
        id: 'media.opening.image',
        label: 'Opening image',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'asset.opening.image',
        provenance: ProjectMediaProvenance(
          source: 'generated',
          creator: 'Avelune Studio',
        ),
        license: ProjectMediaLicense(
          identifier: 'CC0-1.0',
          name: 'CC0 1.0 Universal',
        ),
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'image/png',
          container: 'png',
          codec: 'png',
          sizeBytes: _onePixelPng.length,
          width: 1,
          height: 1,
        ),
      ),
    ],
  );
  final assets = Directory(p.join(root.path, 'assets'));
  await assets.create(recursive: true);
  await File(
    p.join(root.path, assetCatalogStorageKey),
  ).writeAsString(jsonEncode(assetCatalog.toJson()), flush: true);
  await File(
    p.join(root.path, projectMediaCatalogStorageKey),
  ).writeAsString(jsonEncode(mediaCatalog.toJson()), flush: true);
  final blob = File(p.join(root.path, assetBlobStorageKey(artifact)));
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(_onePixelPng, flush: true);
}

Future<void> _writeReferencedPokemonAssets(Directory root) async {
  final mediaDirectory = Directory(
    p.join(root.path, 'data', 'pokemon', 'media'),
  );
  await for (final entity in mediaDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final media =
        jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
    final variants = (media['variants'] as Map<String, dynamic>).values;
    for (final rawVariant in variants) {
      final variant = rawVariant as Map<String, dynamic>;
      final paths = <String>[
        for (final key in const <String>[
          'frontStatic',
          'backStatic',
          'frontShinyStatic',
          'backShinyStatic',
          'icon',
          'party',
          'overworld',
          'portrait',
          'cry',
        ])
          if (variant[key] case final String path) path,
        for (final animation
            in (variant['animations'] as Map<String, dynamic>? ?? const {})
                .values)
          if ((animation as Map<String, dynamic>)['sheet']
              case final String path)
            path,
      ];
      for (final relativePath in paths) {
        final file = File(p.join(root.path, relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          relativePath.endsWith('.ogg')
              ? utf8.encode('OggS cin042')
              : _onePixelPng,
          flush: true,
        );
      }
    }
  }
}

ProjectManifest _project() => ProjectManifest(
  name: 'CIN-042 Canary',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map.start',
      name: 'Start',
      relativePath: 'maps/start.json',
    ),
  ],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 1000,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'background', label: 'Background', zIndex: 0),
        PresentationLayer(id: 'titles', label: 'Titles', zIndex: 1),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visual',
          label: 'Visual',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationVisualClip(
              id: 'background',
              startUs: 0,
              durationUs: 1000,
              layerId: 'background',
              resourceId: 'media.opening.image',
            ),
            PresentationTextClip(
              id: 'title',
              startUs: 0,
              durationUs: 1000,
              layerId: 'titles',
              text: 'Avelune',
            ),
          ],
        ),
      ],
    ),
  ],
  scenes: <SceneAsset>[_preSessionScene(), _completionScene()],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: 'evt_019abcde-8000-7000-8000-000000000042',
          name: 'Completion',
          source: NarrativeEventSourceRef.mapEnter('map.start'),
          conditions: const [],
          sceneId: 'scene.complete',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const [],
  ),
  newGame: const ProjectNewGameConfig(
    enabled: true,
    startMapId: 'map.start',
    startSpawnId: 'spawn.player',
    playerName: 'Player',
    preSessionSceneId: 'scene.pre_session',
    initialParty: <PlayerPokemon>[
      PlayerPokemon(
        speciesId: 'bulbasaur',
        natureId: 'hardy',
        abilityId: 'overgrow',
        level: 5,
        currentHp: 20,
      ),
    ],
  ),
  pokemon: const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    enabled: true,
  ),
);

SceneAsset _preSessionScene() => SceneAsset(
  id: 'scene.pre_session',
  name: 'Pre-session',
  executionProfile: SceneExecutionProfile.preSession,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'opening',
        kind: SceneNodeKind.presentationCinematic,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: 'opening',
        ),
      ),
      SceneNode(
        id: 'name',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.text(
            prompt: SceneInteractionPrompt(
              localizationKey: 'new_game.name',
              fallbackText: 'Votre nom ?',
            ),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.playerName,
            ),
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-opening',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'opening',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'opening-name',
        fromNodeId: 'opening',
        fromPortId: 'completed',
        toNodeId: 'name',
        kind: SceneEdgeKind.presentationCompleted,
      ),
      SceneEdge(
        id: 'name-end',
        fromNodeId: 'name',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

SceneAsset _completionScene() => SceneAsset(
  id: 'scene.complete',
  name: 'Completion',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Complete'),
              summary: SceneLocalizedText(fallback: 'Complete'),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-finish',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'finish',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'finish-end',
        fromNodeId: 'finish',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

final GamePackageExportProfile _exportProfile = GamePackageExportProfile(
  gameId: 'games.pokemap.cin042',
  gameVersion: '1.0.0',
  title: 'CIN-042 Canary',
  authorName: 'Avelune Studio',
  defaultLocale: 'fr',
  supportedLocales: <String>['fr'],
  licensePath: 'LICENSE.txt',
);

GamePackageHostCompatibility _hostCompatibility(
  Iterable<String> requiredCapabilities,
) => GamePackageHostCompatibility(
  hubVersion: Version.parse('1.2.0'),
  runtimeApiVersion: Version.parse('1.4.0'),
  capabilities: requiredCapabilities.toSet(),
  supportedProjectFormats: const <String>{'v7'},
  currentProjectFormat: 'v7',
  supportedSaveFormats: const <int>{1},
);

final class _PreferencesRepository
    implements PlayerPreferencesRepositoryInterface {
  @override
  Future<HubPreferencesRead> load() async => const HubPreferencesRead(
    preferences: PlayerPreferences(),
    source: HubPreferencesSource.defaults,
    currentCorrupt: false,
    backupCorrupt: false,
  );

  @override
  Future<void> save(PlayerPreferences preferences) async {}
}

final class _ControlProfileRepository
    implements ControlProfileRepositoryInterface {
  @override
  Future<PlayerControlProfile> load() async => PlayerControlProfile.standard;

  @override
  Future<void> save(PlayerControlProfile profile) async {}
}

final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
