import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_scene_callbacks.dart';

SpatialSceneCallbacks callbacks({
  required GameState Function() read,
  ProjectManifest? project,
  Future<SceneDialogueRuntimeAwaitableResult> Function(
          SceneDialogueRuntimeDialogueRequest)?
      show,
  Future<SceneBattleRuntimeOutcomeResult> Function(
          SceneBattleRuntimeBattleRequest)?
      battle,
}) =>
    SpatialSceneCallbacks(
      project: project ??
          const ProjectManifest(name: 'Spatial', maps: [], tilesets: []),
      runtimeSourceId: 'activation:forest:1',
      readGameState: read,
      show: show ??
          (_) async => const SceneDialogueRuntimeAwaitableResult.completed(),
      battle: battle ??
          (_) async => const SceneBattleRuntimeOutcomeResult.completed(
              port: SceneBattleRuntimeOutcomePort.victory),
      interactive: (_) async => 'completed',
    );

SceneRuntimePlanIntent condition(SceneConditionSourceKind kind, String id,
        {SceneConditionOperator operator = SceneConditionOperator.isTrue,
        String? value}) =>
    SceneRuntimePlanIntent.evaluateCondition(
        source: SceneConditionSource(
      sourceKind: kind,
      sourceId: id,
      operator: operator,
      value: value,
    ));

void main() {
  test('condition reads the current scene state and both story flag stores',
      () {
    var state = const GameState(saveId: 'save');
    final host = callbacks(read: () => state);
    final flag = condition(SceneConditionSourceKind.factLikeStoryFlag, 'met');
    expect(host.evaluateCondition(flag), 'false');
    state = state.copyWith(storyFlags: const StoryFlags(activeFlags: {'met'}));
    expect(host.evaluateCondition(flag), 'true');
    state = state.copyWith(
        storyFlags: const StoryFlags(),
        progression: const PlayerProgression(storyFlags: ['met']));
    expect(host.evaluateCondition(flag), 'true');
  });

  test('step and consumed conditions preserve canonical equality semantics',
      () {
    final state = const GameState(
        saveId: 'save',
        progression: PlayerProgression(completedStepIds: ['intro']),
        consumedEventIds: {'picked'});
    final host = callbacks(read: () => state);
    expect(
        host.evaluateCondition(condition(
            SceneConditionSourceKind.storyStepCompletion, 'intro',
            operator: SceneConditionOperator.equals,
            value: SceneConditionValues.completed)),
        'true');
    expect(
        host.evaluateCondition(condition(
            SceneConditionSourceKind.consumedEvent, 'picked',
            operator: SceneConditionOperator.isFalse)),
        'false');
    expect(
        host.evaluateCondition(condition(
            SceneConditionSourceKind.storyStepCompletion, 'unvisited',
            operator: SceneConditionOperator.equals,
            value: SceneConditionValues.notCompleted)),
        'true');
  });

  test('inventory conditions use the real authored quantity threshold', () {
    final host = callbacks(
        read: () => const GameState(
              saveId: 'save',
              bag: Bag(entries: [BagEntry(itemId: 'potion', quantity: 2)]),
            ));
    expect(
        host.evaluateCondition(condition(
            SceneConditionSourceKind.inventoryItem, 'potion',
            value: '2')),
        'true');
    expect(
        host.evaluateCondition(condition(
            SceneConditionSourceKind.inventoryItem, 'potion',
            value: '3')),
        'false');
    expect(
        () => host.evaluateCondition(condition(
            SceneConditionSourceKind.inventoryItem, 'potion',
            value: '0')),
        throwsArgumentError);
  });

  test('typed facts and unknown sources use canonical fail-closed resolution',
      () {
    final project = ProjectManifest(
        name: 'Spatial',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
              id: 'count',
              label: 'Count',
              initialValue: NarrativeValue.integer(1)),
        ]);
    final host = callbacks(
        project: project,
        read: () => GameState(
            saveId: 'save',
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
                valuesByFactId: {'count': NarrativeValue.integer(3)})));
    expect(
        host.evaluateCondition(SceneRuntimePlanIntent.evaluateCondition(
            source: SceneConditionSource.factValue(
                factId: 'count',
                operator: NarrativeFactOperator.greaterThan,
                expectedValue: NarrativeValue.integer(2)))),
        'true');
    expect(
        () => host.evaluateCondition(
            condition(SceneConditionSourceKind.fact, 'missing')),
        throwsStateError);
    expect(
        () => host.evaluateCondition(
            condition(SceneConditionSourceKind.worldState, 'weather')),
        throwsUnsupportedError);
  });

  test('dialogue adapter awaits and preserves authored choice outcomes',
      () async {
    SceneDialogueRuntimeDialogueRequest? request;
    final host = callbacks(
        read: () => const GameState(saveId: 'save'),
        show: (value) async {
          request = value;
          return const SceneDialogueRuntimeAwaitableResult.completed(
              outcomeId: 'accepted');
        }).build();
    expect(
        await host.showDialogue(SceneRuntimePlanIntent.showDialogue(
            dialogueId: 'guide',
            yarnNodeName: 'Offer',
            expectedOutcomes: ['accepted', 'declined'])),
        'accepted');
    expect(request!.dialogueId, 'guide');
    expect(request!.yarnNodeName, 'Offer');
    expect(request!.expectedOutcomes, ['accepted', 'declined']);
    await expectLater(
        host.showDialogue(SceneRuntimePlanIntent.showDialogue(
            dialogueId: 'guide', expectedOutcomes: ['declined'])),
        throwsStateError);
  });

  test('static battle adapter keeps template, actor, and terminal result',
      () async {
    SceneBattleRuntimeBattleRequest? request;
    final host = callbacks(
        read: () => const GameState(saveId: 'save'),
        battle: (value) async {
          request = value;
          return const SceneBattleRuntimeOutcomeResult.completed(
              port: SceneBattleRuntimeOutcomePort.defeat);
        }).build();
    expect(
        await host.startBattle(SceneRuntimePlanIntent.startBattle(
            battleKind: 'static',
            trainerId: 'boss-profile',
            battleTemplateId: 'boss-battle',
            npcEntityId: 'boss',
            declaredOutcomes: ['victory', 'defeat'])),
        'defeat');
    expect(request!.battleKind, 'static');
    expect(request!.trainerId, 'boss-profile');
    expect(request!.battleTemplateId, 'boss-battle');
    expect(request!.npcEntityId, 'boss');
  });
}
