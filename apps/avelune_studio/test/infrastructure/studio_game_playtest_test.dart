import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/playtest/studio_game_playtest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:avelune_studio/platform/playtest/studio_game_playtest_view.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../tool/create_example_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full project composes the Presentation runner and commits player input before launch', () async {
    final root = await Directory.systemTemp.createTemp('studio-full-game-');
    addTearDown(() => root.delete(recursive: true));
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final project = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final authored = const SceneActions().createPreSessionScene(
      project.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'jardin',
          startSpawnId: 'depart',
        ),
      ),
      maps: [exampleMap('jardin', 'Jardin des essais')],
      sceneId: 'identity',
      name: 'Identité',
      templateId: 'identitySetup',
      setAsEntrypoint: true,
    );
    await file.writeAsString(jsonEncode(authored.toJson()));
    final game = await StudioGamePlaytest.prepare(
      projectFilePath: file.path,
      onExit: () async {},
      mountGame: (_) async {},
      unmountGame: (_) async {},
      mountSpatial: (_) async {},
      unmountSpatial: (_) async {},
    );
    addTearDown(game.dispose);
    expect(game.newGameFlow.supportsPreSession, isTrue);
    final prepared = await game.newGameFlow.prepare();
    expect(prepared.preSessionRunner, isNotNull);
    expect(prepared.startMap.id, 'jardin');
    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final subscription = interactions.requests.listen((request) {
      if (request is SceneTextInteractionRequest) {
        interactions.resolve(
          SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: 'Camille',
          ),
        );
      } else if (request is SceneConfirmationInteractionRequest) {
        interactions.resolve(
          SceneInteractionResult.confirmed(
            requestId: request.requestId,
            revision: request.revision,
            value: true,
          ),
        );
      }
    });
    addTearDown(subscription.cancel);
    final draft = await prepared.preSessionRunner!.run(
      runId: 'test',
      draft: NewGameDraft.start(
        draftId: 'draft',
        projectRevision: prepared.projectRevision,
        slotId: 'test',
        config: prepared.project.newGame,
      ),
      interactions: interactions,
    );
    expect(draft.playerName, 'Camille');
    expect(await file.readAsString(), jsonEncode(authored.toJson()));
    expect(await game.saves.readLatestSummary(), isNull);
  });
  test('effective reduced motion preferences update the existing Presentation', () async {
    final root = await Directory.systemTemp.createTemp('studio-motion-');
    addTearDown(() => root.delete(recursive: true));
    await writeExampleProject(root);
    final game = await StudioGamePlaytest.prepare(
      projectFilePath: '${root.path}/project.json', onExit: () async {},
      mountGame: (_) async {}, unmountGame: (_) async {},
      mountSpatial: (_) async {}, unmountSpatial: (_) async {},
    );
    addTearDown(game.dispose);
    final controller = game.presentation.controller;
    await game.player.initialize();
    await game.player.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openOptions,
      snapshotRevision: game.player.snapshot.revision,
    ));
    for (final enabled in [true, false]) {
      final preferences = game.player.snapshot.preferences!;
      final result = await game.player.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: game.player.snapshot.revision,
        payload: preferences.copyWith(
          accessibility: GameSessionAccessibilityOptions(reducedMotion: enabled)),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(game.presentation.controller, same(controller));
      expect(controller.reduceMotion, enabled);
    }
  });

  test(
    'Presentation cues choose identity before mounting the authored 3D spawn',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-full-spatial-',
      );
      addTearDown(() => root.delete(recursive: true));
      await writeExampleProject(root);
      final file = File('${root.path}/project.json');
      final original = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      final map = MapData(
        version: ProjectVersion.v9,
        id: 'room',
        name: 'Chambre',
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 3.25, z: 4.75),
          ),
        ),
      );
      final maps = [map];
      final avatars = [
        original.characters.first,
        original.characters.first.copyWith(id: 'second', name: 'Deuxième'),
      ];
      var project = original.copyWith(
        version: ProjectVersion.v9,
        settings: original.settings.copyWith(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(
            id: 'room',
            name: 'Chambre',
            relativePath: 'room.json',
          ),
        ],
        characters: avatars,
        newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: 'room',
          playerAvatarCharacterIds: [for (final avatar in avatars) avatar.id],
        ),
      );
      const actions = SceneActions();
      project = actions.createPreSessionScene(
        project,
        maps: maps,
        sceneId: 'opening',
        name: 'Ouverture',
        templateId: 'minimal',
        setAsEntrypoint: true,
      );
      project = project.copyWith(
        presentationCinematics: [
          PresentationCinematicAsset(
            id: 'opening-film',
            title: 'Ouverture',
            durationUs: 10000,
            tracks: [
              PresentationTrack(
                id: 'cues',
                label: 'Interactions',
                kind: PresentationTrackKind.marker,
                clips: [
                  PresentationMarkerClip(
                    id: 'cue_avatar',
                    startUs: 1000,
                    label: 'Avatar',
                    markerKind: PresentationMarkerKind.interactionCue,
                  ),
                  PresentationMarkerClip(
                    id: 'cue_name',
                    startUs: 2000,
                    label: 'Nom',
                    markerKind: PresentationMarkerKind.interactionCue,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      project = actions.insertPreSessionPresentation(
        project,
        maps: maps,
        sceneId: 'opening',
        nodeId: 'film',
        targetNodeId: 'end',
        presentationCinematicId: 'opening-film',
      );
      project = actions.insertPreSessionInteraction(
        project,
        maps: maps,
        sceneId: 'opening',
        nodeId: 'name',
        targetNodeId: 'end',
        interaction: ScenePreSessionInteractionSpec.text(
          prompt: SceneInteractionPrompt(
            localizationKey: 'name',
            fallbackText: 'Ton nom ?',
          ),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.playerName,
          ),
        ),
        cueBinding: const ScenePreSessionInteractionCueBindingDraft(
          presentationNodeId: 'film',
          markerId: 'cue_name',
        ),
      );
      project = actions.insertPreSessionInteraction(
        project,
        maps: maps,
        sceneId: 'opening',
        nodeId: 'avatar',
        targetNodeId: 'name',
        interaction: ScenePreSessionInteractionSpec.choice(
          prompt: SceneInteractionPrompt(
            localizationKey: 'avatar',
            fallbackText: 'Ton avatar ?',
          ),
          options: [
            for (final avatar in avatars)
              SceneInteractionOption(
                id: avatar.id,
                label: SceneInteractionPrompt(
                  localizationKey: avatar.id,
                  fallbackText: avatar.name,
                ),
              ),
          ],
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.avatarCharacterId,
          ),
        ),
        cueBinding: const ScenePreSessionInteractionCueBindingDraft(
          presentationNodeId: 'film',
          markerId: 'cue_avatar',
        ),
      );
      await file.writeAsString(jsonEncode(project.toJson()));
      await File('${root.path}/room.json')
          .writeAsString(jsonEncode(map.toJson()));
      SpatialExplorationGameSessionRuntime? mounted;
      var mounts = 0;
      final game = await StudioGamePlaytest.prepare(
        projectFilePath: file.path,
        onExit: () async {},
        presentationFrameDeltas: (_) =>
            Stream.periodic(const Duration(milliseconds: 1), (_) => 1000),
        mountGame: (_) async =>
            fail('A spatial project must mount the 3D runtime'),
        unmountGame: (_) async {},
        mountSpatial: (runtime) async {
          expect(runtime.descriptor.grantedCapabilities,
              contains(SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId));
          expect(runtime.descriptor.grantedCapabilities,
              contains(SpatialActorOcclusionCapabilities.capabilityId));
          mounted = runtime;
          mounts++;
        },
        unmountSpatial: (_) async {},
      );
      addTearDown(game.dispose);
      await game.player.initialize();
      final requests = <SceneInteractionRequestKind>[];
      final subscription = game.player.snapshots.listen((snapshot) {
        final request = snapshot.preSessionRequest;
        if (request == null ||
            !snapshot.isActionEnabled(
              RuntimePlayerAction.resolvePreSessionInteraction,
            )) {
          return;
        }
        requests.add(request.kind);
        final response = switch (request.kind) {
          SceneInteractionRequestKind.choice =>
            SceneInteractionResult.choiceSelected(
              requestId: request.requestId,
              revision: request.revision,
              selectedOptionId: 'second',
            ),
          SceneInteractionRequestKind.text =>
            SceneInteractionResult.textSubmitted(
              requestId: request.requestId,
              revision: request.revision,
              value: 'Camille',
            ),
          _ => throw StateError('Unexpected request'),
        };
        unawaited(
          game.player.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.resolvePreSessionInteraction,
              snapshotRevision: snapshot.revision,
              payload: response,
            ),
          ),
        );
      });
      addTearDown(subscription.cancel);
      final result = await game.player.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.newGame,
          snapshotRevision: game.player.snapshot.revision,
          payload: const RuntimePlayerLoadSlot(
            profileId: 'studio',
            slotId: 'test',
          ),
        ),
      );
      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(requests, [
        SceneInteractionRequestKind.choice,
        SceneInteractionRequestKind.text,
      ]);
      expect(mounts, 1);
      expect(mounted!.gameStateSnapshot.trainerProfile.name, 'Camille');
      expect(
        mounted!.gameStateSnapshot.trainerProfile.avatarCharacterId,
        'second',
      );
      expect(mounted!.session!.movement.x, 3.25);
      expect(mounted!.session!.movement.z, 4.75);
      expect(game.player.snapshot.phase, RuntimePlayerPhase.playing);
      Future<RuntimePlayerCommandResult> command(
        RuntimePlayerAction action, {
        Object? payload,
      }) => game.player.dispatch(
        RuntimePlayerCommand(
          action: action,
          snapshotRevision: game.player.snapshot.revision,
          payload: payload,
        ),
      );
      expect(
        (await command(RuntimePlayerAction.openMenu)).status,
        RuntimePlayerCommandStatus.accepted,
      );
      expect(
        (await command(RuntimePlayerAction.save)).status,
        RuntimePlayerCommandStatus.accepted,
      );
      expect(game.saves.envelope, isNotNull);
      expect(
        (await command(
          RuntimePlayerAction.returnToTitle,
          payload: const RuntimePlayerExitRequest(saveBeforeExit: false),
        )).status,
        RuntimePlayerCommandStatus.accepted,
      );
      expect(
        (await command(
          RuntimePlayerAction.continueGame,
          payload: const RuntimePlayerLoadSlot(
            profileId: 'studio',
            slotId: 'test',
          ),
        )).status,
        RuntimePlayerCommandStatus.accepted,
      );
      expect(mounts, 2);
      expect(requests, [
        SceneInteractionRequestKind.choice,
        SceneInteractionRequestKind.text,
      ]);
      expect(mounted!.gameStateSnapshot.trainerProfile.name, 'Camille');
      expect(
        mounted!.gameStateSnapshot.trainerProfile.avatarCharacterId,
        'second',
      );
      expect(mounted!.session!.movement.x, 3.25);
      expect(mounted!.session!.movement.z, 4.75);

      expect(await file.readAsString(), jsonEncode(project.toJson()));
    },
  );
  testWidgets(
    'keeps the same player controller when its prepared view rebuilds',
    (tester) async {
      const audioEvents = MethodChannel('xyz.luan/audioplayers.global/events');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        audioEvents,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          audioEvents,
          null,
        ),
      );
      late Directory root;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('studio-game-controller-');
        await writeExampleProject(root);
      });
      addTearDown(() => root.delete(recursive: true));
      Widget host() => MaterialApp(
        home: StudioGamePlaytestView(
          projectFilePath: '${root.path}/project.json',
          onClose: () {},
        ),
      );
      await tester.pumpWidget(host());
      final shellFinder = find.byType(PlayerRuntimeStartupShell);
      for (
        var attempt = 0;
        attempt < 100 && shellFinder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(shellFinder, findsOneWidget);
      final imageLoader = PlayerImageScope.maybeOf(tester.element(shellFinder));
      expect(imageLoader, isNotNull,
        reason: 'startup logos and posters need the budgeted image loader');
      await tester.runAsync(() async {
        final lease = await imageLoader!(
          '${root.path}/assets/atelier.png', isCurrent: () => true);
        expect(lease.image.width, greaterThan(0));
        expect(lease.image.height, greaterThan(0));
        lease.dispose();
      });
      PokeMapPlayerSessionView sessionView() =>
          tester.widget<PlayerRuntimeStartupShell>(shellFinder).sessionBuilder!(
            tester.element(shellFinder),
            null,
          ) as PokeMapPlayerSessionView;
      expect(sessionView().imageLoader, isNotNull,
        reason: 'the session image scope must keep the startup loader available');
      final first = sessionView().controller;
      await tester.pumpWidget(host());
      expect(identical(sessionView().controller, first), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 8));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    },
  );
}
