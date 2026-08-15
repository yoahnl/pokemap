import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_launch_save.dart';
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the versioned Phase A golden slice exposes a real launch save',
    () async {
      final projectFilePath = _goldenProjectPath();

      final save = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );

      expect(save, isNotNull);
      expect(save!.currentMapId, equals('golden_field'));
      expect(save.party.members, hasLength(2));
      expect(save.party.members.first.speciesId, equals('sproutle'));
    },
  );

  test(
    'startup shell launches New Game through the standalone session port',
    () async {
      final projectFilePath = _goldenProjectPath();
      final manifest = await _loadManifest(projectFilePath);
      final identity = buildStandaloneRuntimeGameIdentity(
        projectFilePath: projectFilePath,
        projectFormat: manifest.version.name,
      );
      expect(
        await StandalonePlayerSaveGateway(
          projectFilePath: projectFilePath,
          identity: identity,
        ).readLatestSummary(),
        isNotNull,
      );
      final launches = <GameSessionDescriptor>[];
      final loadedMapIds = <String>[];
      final host = StandaloneRuntimeStartupHost(
        projectFilePath: projectFilePath,
        manifest: manifest,
        clock: const _ImmediateClock(),
        minimumSplashDuration: Duration.zero,
        sessionPort: CallbackStandaloneRuntimeSessionPort(
          onLaunch: (descriptor, reportProgress, preloadedInitialMap) async {
            launches.add(descriptor);
            final bundle =
                preloadedInitialMap?.bundle ??
                await loadRuntimeMapBundle(
                  projectFilePath: projectFilePath,
                  mapId: 'golden_field',
                );
            preloadedInitialMap?.dispose();
            loadedMapIds.add(bundle.map.id);
            reportProgress(
              const GameSessionLoadingProgress(
                stage: 'ready',
                current: 1,
                total: 1,
              ),
            );
          },
        ),
      );
      addTearDown(host.dispose);

      host.start();
      await _waitForPhase(host, RuntimeStartupPhase.titlePrompt);
      await host.coordinator.dispatch(
        RuntimeStartupCommand(
          action: RuntimeStartupAction.pressStart,
          snapshotRevision: host.snapshot.revision,
        ),
      );
      final player = host.snapshot.playerSnapshot!;

      final launch = host.coordinator.dispatchPlayerCommand(
        startupSnapshotRevision: host.snapshot.revision,
        command: RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: player.revision,
          payload: const RuntimePlayerLoadSlot(
            profileId: standaloneRuntimeProfileId,
            slotId: standaloneRuntimeSlotId,
          ),
        ),
      );
      await _waitForPreSessionInteraction(host);
      final interactionSnapshot = host.snapshot.playerSnapshot!;
      final request = interactionSnapshot.preSessionRequest!;
      final resolution = await host.coordinator.dispatchPlayerCommand(
        startupSnapshotRevision: host.snapshot.revision,
        command: RuntimePlayerCommand(
          action: RuntimePlayerAction.resolvePreSessionInteraction,
          snapshotRevision: interactionSnapshot.revision,
          payload: SceneInteractionResult.confirmed(
            requestId: request.requestId,
            revision: request.revision,
            value: true,
          ),
        ),
      );
      final result = await launch;

      expect(resolution.status, RuntimePlayerCommandStatus.accepted);
      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(launches, hasLength(1));
      expect(launches.single.launchMode, GameSessionLaunchMode.newGame);
      expect(loadedMapIds, <String>['golden_field']);
      await _waitForPhase(host, RuntimeStartupPhase.completed);
      expect(host.snapshot.phase, RuntimeStartupPhase.completed);
    },
  );

  test(
    'startup shell discovers and continues the canonical adjacent save',
    () async {
      final projectFilePath = _goldenProjectPath();
      final manifest = await _loadManifest(projectFilePath);
      final launches = <GameSessionDescriptor>[];
      final restoredPositions = <String>[];
      final host = StandaloneRuntimeStartupHost(
        projectFilePath: projectFilePath,
        manifest: manifest,
        clock: const _ImmediateClock(),
        minimumSplashDuration: Duration.zero,
        sessionPort: CallbackStandaloneRuntimeSessionPort(
          onLaunch: (descriptor, _, preloadedInitialMap) async {
            launches.add(descriptor);
            final save = await loadRuntimeHostLaunchSaveData(
              projectFilePath: projectFilePath,
            );
            final bundle = preloadedInitialMap!.bundle;
            final restoredSave = save!;
            restoredPositions.add(
              '${bundle.map.id}:${restoredSave.playerPosition.x},${restoredSave.playerPosition.y}',
            );
            preloadedInitialMap.dispose();
          },
        ),
      );
      addTearDown(host.dispose);

      host.start();
      await _waitForPhase(host, RuntimeStartupPhase.titlePrompt);
      expect(host.snapshot.playerSnapshot!.hasDiscoveredSave, isTrue);
      await host.coordinator.dispatch(
        RuntimeStartupCommand(
          action: RuntimeStartupAction.pressStart,
          snapshotRevision: host.snapshot.revision,
        ),
      );
      final player = host.snapshot.playerSnapshot!;

      final result = await host.coordinator.dispatchPlayerCommand(
        startupSnapshotRevision: host.snapshot.revision,
        command: RuntimePlayerCommand(
          action: RuntimePlayerAction.continueGame,
          snapshotRevision: player.revision,
        ),
      );

      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(launches, hasLength(1));
      expect(launches.single.launchMode, GameSessionLaunchMode.continueGame);
      expect(launches.single.saveReadHandle, 'standalone-save-v1');
      expect(restoredPositions, <String>['golden_field:1,1']);
      await _waitForPhase(host, RuntimeStartupPhase.completed);
      expect(host.snapshot.phase, RuntimeStartupPhase.completed);
    },
  );

  test('standalone forwards the complete V10 presentation', () async {
    final acceptanceProject =
        jsonDecode(
              await File(
                '${Directory.current.path}/golden_personalization_v3/project.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    final profile = ProjectPresentationProfile.fromJson(
      Map<String, dynamic>.from(acceptanceProject['presentation'] as Map),
    );
    final projectFilePath = _goldenProjectPath();
    final manifest = (await _loadManifest(
      projectFilePath,
    )).copyWith(presentation: profile);
    final adapter = StandaloneRuntimeStartupAdapter(
      projectFilePath: projectFilePath,
      manifest: manifest,
    );

    final loaded = await adapter.loadPresentationProfile();
    expect(loaded, profile);
    final presentation = player_ui.RuntimePlayerPresentation.fromProfile(
      loaded!,
    );
    expect(
      presentation.title.layoutVariant,
      player_ui.PlayerTitleLayoutVariant.cinematic,
    );
    final pauseActions = presentation.pausePresentation.actionLabels;
    expect(
      pauseActions[player_ui.PlayerPauseAction.pokedex],
      'Carnet de route',
    );
    expect(presentation.typography.combatFallback, <String>['monospace']);
    expect(
      presentation.windowProfile
          ?.resolve(ProjectWindowRole.battle)
          .cornerRadius,
      12,
    );
    expect(
      presentation.layoutProfile?.battle?.regular.slot,
      ProjectPresentationLayoutSlot.right,
    );
    expect(
      presentation.dialogueProfile?.placement,
      ProjectDialoguePlacement.bottom,
    );
    expect(
      presentation.battleProfile?.commandLayout,
      ProjectBattleCommandLayout.radial,
    );
  });

  test('standalone loads the complete V3 acceptance project', () async {
    final projectFilePath =
        '${Directory.current.path}/golden_personalization_v3/project.json';
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: 'vermeil_village',
    );

    expect(bundle.manifest.name, 'L’Aube de Vermeil');
    expect(bundle.map.id, 'vermeil_village');
    expect(bundle.map.entities.map((entity) => entity.id), contains('npc_leo'));
    expect(
      bundle.manifest.presentation?.schemaVersion,
      ProjectPresentationProfile.supportedSchemaVersion,
    );
  });

  test(
    'standalone presentation resolution cannot escape the project root',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-standalone-startup-',
      );
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(
        '${root.path}${Platform.pathSeparator}project.json',
      );
      await projectFile.writeAsString('{}');
      final inside = File('${root.path}${Platform.pathSeparator}hero.png');
      await inside.writeAsBytes(const <int>[0, 1, 2]);
      final outside = File('${root.parent.path}${Platform.pathSeparator}x.png');
      await outside.writeAsBytes(const <int>[3, 4, 5]);
      addTearDown(() async {
        if (await outside.exists()) await outside.delete();
      });
      final manifest = await _loadManifest(_goldenProjectPath());
      final adapter = StandaloneRuntimeStartupAdapter(
        projectFilePath: projectFile.path,
        manifest: manifest,
      );

      expect(await adapter.resolveImage('hero.png'), isNotNull);
      expect(await adapter.resolveImage('../x.png'), isNull);
      expect(await adapter.resolveMedia('missing.mp4'), isNull);
    },
  );

  test('missing standalone presentation media stays non-blocking', () async {
    final projectFile = File(_goldenProjectPath());
    final fixture = await _loadManifest(_goldenProjectPath());
    final manifest = fixture.copyWith(
      presentation: ProjectPresentationProfile(
        branding: const ProjectBrandingProfile(
          heroPath: 'media/missing-hero.png',
          titleMusicPath: 'media/missing-title.ogg',
        ),
        intro: ProjectIntroVideoProfile.fromLandscape(
          videoPath: 'media/missing-intro.mp4',
          posterPath: 'media/missing-poster.png',
          durationMilliseconds: 1200,
          width: 1280,
          height: 720,
          bitrateKbps: 1200,
          sizeBytes: 1024,
          videoCodec: 'h264',
        ),
      ),
    );
    final host = StandaloneRuntimeStartupHost(
      projectFilePath: projectFile.path,
      manifest: manifest,
      clock: const _ImmediateClock(),
      minimumSplashDuration: Duration.zero,
      sessionPort: CallbackStandaloneRuntimeSessionPort(
        onLaunch: (_, _, _) async {},
      ),
    );
    addTearDown(host.dispose);

    host.start();
    await _waitForPhase(host, RuntimeStartupPhase.titlePrompt);

    expect(
      host.snapshot.diagnostics.map((item) => item.code),
      containsAll(<String>{
        'introVideoUnavailable',
        'introPosterUnavailable',
        'titleHeroUnavailable',
        'titleMusicUnavailable',
      }),
    );
  });

  test(
    'a malformed adjacent save becomes a recoverable startup error',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-standalone-invalid-save-',
      );
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(
        '${root.path}${Platform.pathSeparator}project.json',
      );
      await projectFile.writeAsString('{}');
      await File(
        '${root.path}${Platform.pathSeparator}$kRuntimeHostLaunchSaveFileName',
      ).writeAsString('{ invalid json');
      final host = StandaloneRuntimeStartupHost(
        projectFilePath: projectFile.path,
        manifest: await _loadManifest(_goldenProjectPath()),
        minimumSplashDuration: Duration.zero,
        sessionPort: CallbackStandaloneRuntimeSessionPort(
          onLaunch: (_, _, _) async {},
        ),
      );
      addTearDown(host.dispose);

      host.start();
      await _waitForPhase(host, RuntimeStartupPhase.recoverableError);

      expect(host.snapshot.canRetry, isTrue);
      expect(
        host.snapshot.playerSnapshot?.failure?.code,
        GameSessionFailureCode.storage,
      );
    },
  );

  test(
    'the standalone canonical slot commits through the runtime gateway',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-standalone-save-commit-',
      );
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(
        '${root.path}${Platform.pathSeparator}project.json',
      );
      await projectFile.writeAsString('{}');
      final manifest = await _loadManifest(_goldenProjectPath());
      final identity = buildStandaloneRuntimeGameIdentity(
        projectFilePath: projectFile.path,
        projectFormat: manifest.version.name,
      );
      final gateway = StandalonePlayerSaveGateway(
        projectFilePath: projectFile.path,
        identity: identity,
      );
      final fixtureSave = await loadRuntimeHostLaunchSaveData(
        projectFilePath: _goldenProjectPath(),
      );
      final createdAt = DateTime.utc(2026, 8, 9, 12);
      const saveId = 'e74ef416-9ad1-5d32-a420-20f7eb375b6c';
      final descriptor = GameSessionDescriptor(
        sessionId: 'standalone-save-test',
        sessionToken: 'standalone-save-secret',
        identity: identity,
        profileId: standaloneRuntimeProfileId,
        slotId: standaloneRuntimeSlotId,
        launchMode: GameSessionLaunchMode.newGame,
        installedVersionHandle: 'standalone-save-fixture',
        runtimeApiVersion: '1.0.0',
        grantedCapabilities: const <String>{},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
        initialGameState: const GameState(
          saveId: standaloneRuntimeSlotId,
          currentMapId: 'golden_field',
        ),
      );

      await expectLater(
        gateway.commit(
          GameSessionCheckpointCommit(
            descriptor: descriptor.publicContext,
            checkpoint: GameSessionCheckpoint(
              saveId: saveId,
              createdAt: createdAt,
              updatedAt: createdAt,
              playTimeSeconds: 0,
              state: gameStateFromSaveData(
                fixtureSave!,
              ).copyWith(saveId: saveId).toJson(),
            ),
            status: SaveStatus.active,
          ),
        ),
        throwsA(isA<UnsupportedSaveSchema>()),
      );
      expect(
        File(
          '${root.path}${Platform.pathSeparator}'
          '$kRuntimeHostLaunchSaveFileName',
        ).existsSync(),
        isFalse,
      );

      await gateway.commit(
        GameSessionCheckpointCommit(
          descriptor: descriptor.publicContext,
          checkpoint: GameSessionCheckpoint(
            saveId: saveId,
            createdAt: createdAt,
            updatedAt: createdAt.add(const Duration(minutes: 3)),
            playTimeSeconds: 180,
            state: strictGameStateSaveJson(
              gameStateFromSaveData(fixtureSave).copyWith(saveId: saveId),
            ),
          ),
          status: SaveStatus.active,
        ),
      );

      final committed = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFile.path,
      );
      expect(committed?.saveId, saveId);
      expect(committed?.currentMapId, 'golden_field');
      expect(await gateway.readLatestSummary(), isNotNull);
    },
  );

  test('the standalone splash waits for the real minimum gate', () async {
    final projectFilePath = _goldenProjectPath();
    final clock = _GateClock();
    final host = StandaloneRuntimeStartupHost(
      projectFilePath: projectFilePath,
      manifest: await _loadManifest(projectFilePath),
      clock: clock,
      minimumSplashDuration: const Duration(seconds: 10),
      sessionPort: CallbackStandaloneRuntimeSessionPort(
        onLaunch: (_, _, _) async {},
      ),
    );
    addTearDown(host.dispose);

    host.start();
    await _waitForPreparation(host);

    expect(host.snapshot.phase, RuntimeStartupPhase.splash);
    expect(host.snapshot.isMinimumElapsed, isFalse);
    clock.complete();
    await _waitForPhase(host, RuntimeStartupPhase.titlePrompt);
  });

  test(
    'the developer picker adopts the canonical startup and session surfaces',
    () async {
      final source = await File('lib/main.dart').readAsString();

      expect(source, contains('PlayerRuntimeStartupShell('));
      expect(source, contains('PokeMapPlayerSessionView('));
      expect(source, contains("'standalone-runtime-player-view'"));
      expect(source, contains('StandaloneRuntimeStartupHost('));
      expect(source, isNot(contains('POKEMAP_RUNTIME_STARTUP_SHELL')));
      expect(source, isNot(contains('_runtimeStartupShellEnabled')));
      expect(
        source,
        contains('onPressed: _loading ? null : _launchSelectedProject'),
      );
      expect(source, isNot(contains('onPressed: _loading ? null : _load,')));
    },
  );
}

String _goldenProjectPath() =>
    '${Directory.current.path}${Platform.pathSeparator}golden_battle_slice${Platform.pathSeparator}project.json';

Future<ProjectManifest> _loadManifest(String path) async =>
    ProjectManifest.fromJson(
      jsonDecode(await File(path).readAsString()) as Map<String, dynamic>,
    );

Future<void> _waitForPhase(
  StandaloneRuntimeStartupHost host,
  RuntimeStartupPhase phase,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (host.snapshot.phase == phase) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(
    'Timed out waiting for ${phase.name}; '
    'current phase is ${host.snapshot.phase.name}, '
    'startup failure=${host.snapshot.failure?.code}, '
    'player phase=${host.snapshot.playerSnapshot?.phase.name}, '
    'player failure=${host.snapshot.playerSnapshot?.failure?.code.name}.',
  );
}

Future<void> _waitForPreparation(StandaloneRuntimeStartupHost host) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (host.snapshot.isPreparationReady) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for standalone startup preparation.');
}

Future<void> _waitForPreSessionInteraction(
  StandaloneRuntimeStartupHost host,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (host.snapshot.playerSnapshot?.preSessionRequest != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for the standalone preSession interaction.');
}

final class _GateClock implements RuntimeStartupClock {
  final Completer<void> _gate = Completer<void>();

  @override
  Future<void> delay(Duration duration) => _gate.future;

  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }
}

final class _ImmediateClock implements RuntimeStartupClock {
  const _ImmediateClock();

  @override
  Future<void> delay(Duration duration) async {}
}
