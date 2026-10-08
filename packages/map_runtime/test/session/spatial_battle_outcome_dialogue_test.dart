import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'spatial_exploration_game_session_runtime_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in ['trainer', 'static']) {
    test(
        '$kind Scene battle delivers its outcome dialogue with live host input',
        () async {
      final fixture = await _fixture(kind);
      final runtime = SpatialExplorationGameSessionRuntime(
        descriptor: fixtures.descriptor(initialState: fixture.state),
        projectFilePath: () async => p.join(fixture.root.path, 'project.json'),
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: fixture.bundle),
        mountSession: (_) async {},
        unmountSession: (_) async {},
      );
      addTearDown(runtime.dispose);
      await runtime.load((_) {});
      await _until(
          () => runtime.battle?.displaySession != null,
          () =>
              '${runtime.session?.interactionError.value} / ${runtime.battle?.error}');
      final battle = runtime.battle!;
      expect(runtime.inputAuthority.value.context, RuntimeInputContext.battle);
      expect(
          battle.context!.request.kind,
          kind == 'trainer'
              ? RuntimeBattleKind.trainer
              : RuntimeBattleKind.staticEncounter);
      for (var i = 0; i < 500 && battle.postBattleOverlay == null; i++) {
        _primary(runtime);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(battle.postBattleOverlay, isNotNull, reason: '${battle.error}');
      expect(battle.engineState!.outcome!.isVictory, true);
      for (var i = 0;
          i < 500 && runtime.dialoguePresentationListenable.value == null;
          i++) {
        _primary(runtime);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final dialogue = runtime.dialoguePresentationListenable.value;
      expect(dialogue, isNotNull,
          reason:
              '${runtime.session!.interactionError.value} / ${battle.error}');
      expect(battle.phase, SpatialBattlePhase.idle);
      expect(battle.isActive, false);
      expect(
          runtime.inputAuthority.value.context, RuntimeInputContext.dialogue);
      expect(runtime.inputAuthority.value.acceptsRuntimeInput, true);
      expect(dialogue!.fullText, 'Victoire !');
      final beforeReward = runtime.gameStateSnapshot;
      expect(beforeReward.completedBattleRequestIds, hasLength(1));
      expect(beforeReward.party.members.first.currentPpByMoveId!['tackle'],
          lessThan(35));
      expect(beforeReward.party.members.first.experience,
          greaterThan(fixture.state.party.members.first.experience!));
      _primary(runtime);
      expect(runtime.dialoguePresentationListenable.value!.fullText,
          'Voilà ta récompense.');
      expect(runtime.gameStateSnapshot.trainerProfile.money,
          beforeReward.trainerProfile.money);
      _primary(runtime);
      await runtime.gameplayReady.timeout(const Duration(seconds: 3));
      await _until(
          () =>
              runtime.inputAuthority.value.context ==
              RuntimeInputContext.overworld,
          () => '${runtime.session!.interactionError.value}');
      final completed = runtime.gameStateSnapshot;
      expect(runtime.dialoguePresentationListenable.value, isNull);
      expect(completed.trainerProfile.money,
          beforeReward.trainerProfile.money + 5);
      expect(completed.narrativeEventProgress.consumedNarrativeEventIds,
          {_eventId(1), _eventId(2)});
      expect(completed.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty);
      expect(completed.completedBattleRequestIds,
          beforeReward.completedBattleRequestIds);
      expect(
          completed.playerSpatialPosition, fixture.state.playerSpatialPosition);
      _primary(runtime);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(runtime.gameStateSnapshot.trainerProfile.money,
          completed.trainerProfile.money);
    });
  }
}

void _primary(SpatialExplorationGameSessionRuntime runtime) {
  expect(
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary)),
      true);
  runtime.handleInput(
      const RuntimeInputEvent.release(RuntimeInputControl.primary));
}

Future<void> _until(bool Function() ready, String Function() diagnostic) async {
  for (var i = 0; i < 600 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ready(), true, reason: diagnostic());
}

String _eventId(int id) =>
    'evt_019abcde-0000-7000-8000-${id.toString().padLeft(12, '0')}';

NarrativeEventRecord _event(
        int id, NarrativeEventSourceRef source, String sceneId) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: _eventId(id),
            name: sceneId,
            source: source,
            conditions: const [],
            sceneId: sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: id,
            resetPolicy: const NarrativeEventResetPolicy.never()),
        enabled: true);

SceneAsset _battleScene(String kind) => SceneAsset(
    id: 'battle',
    name: 'Battle',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'fight',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
              battleKind: kind,
              trainerId: 'trainer_rookie',
              battleTemplateId:
                  kind == 'static' ? 'static:trainer_rookie' : null,
              declaredOutcomes: const ['victory', 'defeat'])),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start-fight',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'fight',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'victory',
          fromNodeId: 'fight',
          fromPortId: 'victory',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleVictory),
      SceneEdge(
          id: 'defeat',
          fromNodeId: 'fight',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat),
    ]));

SceneAsset _rewardScene() => SceneAsset(
    id: 'reward',
    name: 'Reward',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'talk',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'victory')),
      SceneNode(
          id: 'grant',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
              SceneConsequence.giveMoney(amount: 5))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start-talk',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'talk',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'talk-grant',
          fromNodeId: 'talk',
          fromPortId: 'completed',
          toNodeId: 'grant',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'grant-end',
          fromNodeId: 'grant',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted),
    ]));

Future<({Directory root, RuntimeMapBundle bundle, GameState state})> _fixture(
    String kind) async {
  final source = p.normalize(p.join(Directory.current.path, '..', '..',
      'examples', 'playable_runtime_host', 'golden_battle_slice'));
  final original = await loadRuntimeMapBundle(
      projectFilePath: p.join(source, 'project.json'), mapId: 'golden_field');
  final root = await Directory.systemTemp.createTemp('spatial-battle-outcome-');
  addTearDown(() => root.delete(recursive: true));
  for (final file
      in Directory(source).listSync(recursive: true).whereType<File>()) {
    final target = File(p.join(root.path, p.relative(file.path, from: source)));
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  await File(p.join(root.path, 'hero.png'))
      .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
  await File(p.join(root.path, 'victory.json')).writeAsBytes(
      const RuntimeDialogueDocumentCodec()
          .encodeUtf8(RuntimeDialogueDocument(nodes: [
    RuntimeDialogueNode(title: 'Start', steps: [
      RuntimeDialogueLine('Victoire !'),
      RuntimeDialogueLine('Voilà ta récompense.')
    ])
  ])));
  final evolutions =
      Directory(p.join(root.path, original.manifest.pokemon.evolutionsDir));
  await evolutions.create(recursive: true);
  for (final species in ['sproutle', 'sparkitten']) {
    await File(p.join(evolutions.path, '$species.json')).writeAsString(
        jsonEncode(
            {'schemaVersion': 1, 'speciesId': species, 'evolutions': []}));
  }
  final project = original.manifest.copyWith(
    version: ProjectVersion.v9,
    settings: original.manifest.settings.copyWith(
        dimension: ProjectDimension.threeD, defaultPlayerCharacterId: 'hero'),
    newGame: ProjectNewGameConfig(enabled: true, startMapId: original.map.id),
    characters: [
      ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'unused',
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                  state: CharacterAnimationState.walk,
                  direction: direction,
                  sourceAssetId: 'hero-sheet',
                  frames: const [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0, y: 0, width: 32, height: 32))
                  ])
          ])
    ],
    trainers: [
      original.manifest.trainers.single
          .copyWith(tags: kind == 'static' ? ['static-encounter'] : [], team: [
        original.manifest.trainers.single.team.single
            .copyWith(level: 2, moves: ['growl'])
      ])
    ],
    dialogues: [
      const ProjectDialogueEntry(
          id: 'victory', name: 'Victory', relativePath: 'victory.json')
    ],
    scenes: [_battleScene(kind), _rewardScene()],
    eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        legacyClaims: const [],
        records: [
          _event(1, NarrativeEventSourceRef.mapEnter('golden_field'), 'battle'),
          _event(
              2,
              NarrativeEventSourceRef.outcomeReceived(NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.battle,
                  producerId: '$kind:trainer_rookie',
                  outcomeId: 'victory')),
              'reward'),
        ]),
  );
  final map = MapData(
      version: ProjectVersion.v9,
      id: original.map.id,
      name: original.map.name,
      size: original.map.size,
      spatialScene: MapSpatialScene(
          width: original.map.size.width, depth: original.map.size.height));
  final bundle = original.copyWith(
      manifest: project,
      map: map,
      projectRootDirectory: root.path,
      characterAnimationAbsolutePathsByAssetId: {
        'hero-sheet': p.join(root.path, 'hero.png')
      });
  final save = SaveData.fromJson(jsonDecode(
      await File(p.join(source, 'runtime_host_launch_save.json'))
          .readAsString()) as Map<String, dynamic>);
  final originalState = gameStateFromSaveData(save);
  final hero = originalState.party.members.first.copyWith(
      level: 50,
      experience: 125000,
      currentHp: 100,
      knownMoveIds: ['tackle'],
      currentPpByMoveId: {'tackle': 35});
  final state = originalState.copyWith(
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      party: originalState.party.copyWith(members: [hero]),
      playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5),
      trainerProfile:
          originalState.trainerProfile.copyWith(avatarCharacterId: 'hero'));
  return (root: root, bundle: bundle, state: state);
}
