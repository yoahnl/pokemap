import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_trainer_defeated_condition.dart';

import '../../map_authoring/test/support/standard_event_template_fixture.dart'
    show templateProject, templateMap, templateSpec, templateItems;

void main() {
  for (final changed in [false, true]) {
    test('compiled conditional NPC selects the coordinated ${changed ? 'after' : 'before'} page', () {
      final base = templateProject();
      final project = base.copyWith(characters: [
        ...base.characters,
        const ProjectCharacterEntry(id: 'alternate', name: 'Autre apparence', tilesetId: 'people'),
      ]);
      final original = templateSpec(StandardEventTemplateKind.conditionalNpc);
      final projection = compileStandardEventTemplate(project: project, maps: [templateMap()],
        spec: StandardEventTemplateSpec(kind: original.kind, mapId: original.mapId, entityId: original.entityId,
          name: original.name, parameters: {...original.parameters, 'alternateCharacterId': 'alternate'}));
      final published = project.copyWith(scenes: projection.scenes, eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1, mode: EventSystemMode.v2Only, records: projection.events, legacyClaims: []));
      final state = GameState(saveId: 'conditional', currentMapId: 'room',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(overridesByFactId: {'met': changed}));
      final reloaded = gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
      final projected = projectMapEntityPresentation(project: published, gameState: reloaded, map: projection.map,
        entity: projection.map.entities.single)!;
      expect(projected.npc!.characterId, changed ? 'alternate' : 'person');
      expect(projected.blocksMovement, isTrue);
      expect(projection.preview(project: published, gameState: reloaded).activePageId,
        projection.pages[changed ? 1 : 0].id);
    });
  }

  test('compiled pickup stays retryable when full and gives the item after cold reload', () async {
    final projection = _compile(StandardEventTemplateKind.pickup);
    final project = _project(projection).copyWith(
      bagCapacity: const ProjectBagCapacity(
        pockets: {'items': BagPocketCapacity(maxQuantityPerItem: 1)},
      ),
    );
    final full = const GameState(
      saveId: 'pickup',
      currentMapId: 'room',
      bag: Bag(entries: [BagEntry(itemId: 'key', quantity: 1)]),
    );
    final pending = await _execute(projection, project, full);
    expect(pending.consumeOneShot, isFalse);
    expect(pending.updatedGameState.bag, full.bag);
    expect(
      projection
          .preview(project: project, gameState: pending.updatedGameState)
          .visible,
      isTrue,
    );
    final reloaded = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(pending.updatedGameState),
    );
    final space = const BagOperations().take(
      BagTakeRequest(bag: reloaded.bag, itemId: 'key', quantity: 1),
    );
    final received = await _execute(
      projection,
      project,
      reloaded.copyWith(bag: space.bag),
    );
    expect(received.consumeOneShot, isTrue);
    expect(
      const BagOperations().quantityOf(received.updatedGameState.bag, 'key'),
      1,
    );
    expect(
      received
          .updatedGameState
          .narrativeEventProgress
          .consumedNarrativeEventIds,
      isEmpty,
    );
    final completed = received.updatedGameState.copyWith(
      narrativeEventProgress: NarrativeEventProgress(
        consumedNarrativeEventIds: projection.events.map((event) => event.id),
      ),
    );
    final saved = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(completed),
    );
    expect(
      projection.preview(project: project, gameState: saved).visible,
      isFalse,
    );
    expect(
      projectMapEntityPresentation(
        project: project,
        gameState: saved,
        map: projection.map,
        entity: projection.map.entities.single,
      ),
      isNull,
    );
  });

  for (final hasKey in [false, true]) {
    test(
      'compiled door ${hasKey ? 'passes' : 'refuses'} through the inventory runtime guard',
      () async {
        final projection = _compile(StandardEventTemplateKind.lockedDoor);
        final project = _project(projection);
        final state = GameState(
          saveId: 'door',
          currentMapId: 'room',
          bag: Bag(
            entries: [if (hasKey) const BagEntry(itemId: 'key', quantity: 1)],
          ),
        );
        final warps = <SceneInteractiveCommand>[];
        final dialogues = <String>[];
        final result = await _execute(
          projection,
          project,
          state,
          onInteractive: warps.add,
          onDialogue: dialogues.add,
        );
        expect(
          warps.whereType<SceneWarpInteractiveCommand>(),
          hasKey ? hasLength(1) : isEmpty,
        );
        expect(dialogues, hasKey ? isEmpty : ['hello']);
        expect(result.updatedGameState.bag, state.bag);
        expect(
          projection.preview(project: project, gameState: state).blocksMovement,
          isTrue,
        );
      },
    );
  }

  for (final outcome in ['victory', 'defeat']) {
    test(
      'compiled trainer follows native $outcome and preserves the host victory state',
      () async {
        final projection = _compile(StandardEventTemplateKind.trainer);
        final project = _project(projection);
        final dialogues = <String>[];
        final result = await _execute(
          projection,
          project,
          const GameState(saveId: 'trainer', currentMapId: 'room'),
          battleOutcome: outcome,
          onDialogue: dialogues.add,
        );
        expect(
          dialogues,
          outcome == 'victory' ? ['hello', 'after'] : ['hello'],
        );
        expect(
          result.updatedGameState.storyFlags.activeFlags.contains(
            'trainer_defeated:trainer',
          ),
          outcome == 'victory',
        );
        expect(result.consumeOneShot, outcome == 'victory');
        final reloaded = gameStateFromStrictSaveJson(
          strictGameStateSaveJson(result.updatedGameState),
        );
        final secondDialogues = <String>[];
        var battles = 0;
        await _execute(
          projection,
          project,
          reloaded,
          onDialogue: secondDialogues.add,
          onBattle: () => battles++,
        );
        expect(battles, outcome == 'victory' ? 0 : 1);
        expect(secondDialogues.first, outcome == 'victory' ? 'after' : 'hello');
      },
    );
  }
}

StandardEventTemplateProjection _compile(StandardEventTemplateKind kind) =>
    compileStandardEventTemplate(
      project: templateProject(),
      maps: [templateMap()],
      spec: templateSpec(kind),
      itemCatalog: templateItems(),
    );

ProjectManifest _project(StandardEventTemplateProjection projection) =>
    templateProject().copyWith(
      scenes: projection.scenes,
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: projection.events,
        legacyClaims: [],
      ),
    );

Future<NarrativeSceneExecutionCompleted> _execute(
  StandardEventTemplateProjection projection,
  ProjectManifest project,
  GameState initial, {
  void Function(SceneInteractiveCommand)? onInteractive,
  void Function(String)? onDialogue,
  void Function()? onBattle,
  String battleOutcome = 'victory',
}) async {
  var current = initial;
  final result = await executeNarrativeEventScene(
    request: NarrativeSceneExecutionRequest(
      eventId: projection.events.first.id,
      sceneId: projection.scenes.first.id,
      executionId: 'runtime-template-test',
      gameState: initial,
    ),
    project: project,
    mapsById: {projection.map.id: projection.map},
    currentGameState: () => current,
    consequenceWriter: SceneConsequenceRuntimeWriter(
      project: project,
      itemCatalog: ItemCatalogSnapshot.fromCatalog(templateItems()),
    ),
    callbacks: SceneRuntimeHostCallbacks(
      evaluateCondition: (intent) {
        final source = intent.conditionSource!;
        final passed =
            source.sourceKind == SceneConditionSourceKind.inventoryItem
            ? evaluateSceneInventoryCondition(
                source: source,
                gameState: current,
              )
            : evaluateSceneTrainerDefeatedCondition(
                source: source,
                gameState: current,
              );
        return passed ? 'true' : 'false';
      },
      showDialogue: (intent) {
        onDialogue?.call(intent.dialogueId!);
        return 'completed';
      },
      startBattle: (_) {
        onBattle?.call();
        if (battleOutcome == 'victory') {
          current = current.copyWith(
            storyFlags: StoryFlags(
              activeFlags: {
                ...current.storyFlags.activeFlags,
                'trainer_defeated:trainer',
              },
            ),
          );
        }
        return battleOutcome;
      },
      playCinematic: (_) => throw StateError('Unexpected cinematic'),
      executeInteractiveCommand: (intent) {
        onInteractive?.call(intent.interactiveCommand!);
        return 'completed';
      },
    ),
  );
  expect(
    result,
    isA<NarrativeSceneExecutionCompleted>(),
    reason: result.toString(),
  );
  return result as NarrativeSceneExecutionCompleted;
}
